allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    val configureNamespace = { proj: Project ->
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespaceValue = getNamespace.invoke(android) as? String
                if (namespaceValue == null || namespaceValue.isEmpty()) {
                    // Intentar extraer el package del AndroidManifest.xml para que coincida con el namespace
                    val manifestFile = proj.projectDir.resolve("src/main/AndroidManifest.xml")
                    var manifestPackage: String? = null
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val match = Regex("""package\s*=\s*"([^"]+)"""").find(content)
                        if (match != null) {
                            manifestPackage = match.groupValues[1]
                        }
                    }

                    val finalNamespace = manifestPackage ?: "com.tocadiscos.${proj.name.replace(Regex("[^a-zA-Z0-9_]"), "_")}"
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, finalNamespace)
                }
            } catch (e: Exception) {
                // Ignorar si no se puede acceder a la propiedad o configurar
            }
        }
    }

    val configureJvmTarget = { proj: Project ->
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val getCompileOptions = android.javaClass.getMethod("getCompileOptions")
                val compileOptions = getCompileOptions.invoke(android)
                val javaVersionClass = compileOptions.javaClass.classLoader.loadClass("org.gradle.api.JavaVersion")
                val version17 = javaVersionClass.getMethod("valueOf", String::class.java).invoke(null, "VERSION_17")
                
                compileOptions.javaClass.getMethod("setSourceCompatibility", javaVersionClass).invoke(compileOptions, version17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", javaVersionClass).invoke(compileOptions, version17)
            } catch (e: Exception) {}
            
            try {
                val getKotlinOptions = android.javaClass.getMethod("getKotlinOptions")
                val kotlinOptions = getKotlinOptions.invoke(android)
                kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")
            } catch (e: Exception) {}
        }
    }

    if (project.state.executed) {
        configureNamespace(project)
        configureJvmTarget(project)
    } else {
        project.afterEvaluate {
            configureNamespace(project)
            configureJvmTarget(project)
        }
    }

    // Alinear JVM targets entre Java y Kotlin para evitar errores de compilación de forma segura entre classloaders
    tasks.configureEach {
        if (this.javaClass.name.contains("JavaCompile")) {
            try {
                this.javaClass.getMethod("setSourceCompatibility", String::class.java).invoke(this, "17")
            } catch (e: Exception) {
                try {
                    this.javaClass.getMethod("setSourceCompatibility", Any::class.java).invoke(this, "17")
                } catch (e2: Exception) {}
            }
            try {
                this.javaClass.getMethod("setTargetCompatibility", String::class.java).invoke(this, "17")
            } catch (e: Exception) {
                try {
                    this.javaClass.getMethod("setTargetCompatibility", Any::class.java).invoke(this, "17")
                } catch (e2: Exception) {}
            }
        }
        if (this.javaClass.name.contains("KotlinCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "17")
            } catch (e: Exception) {
                // Ignorar si no se puede configurar la propiedad
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
