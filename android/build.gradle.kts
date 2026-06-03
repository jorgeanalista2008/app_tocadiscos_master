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

    if (project.state.executed) {
        configureNamespace(project)
    } else {
        project.afterEvaluate {
            configureNamespace(project)
        }
    }

    // Alinear JVM targets entre Java y Kotlin para evitar errores de compilación
    tasks.configureEach {
        if (this is JavaCompile) {
            sourceCompatibility = "1.8"
            targetCompatibility = "1.8"
        }
        if (this.javaClass.name.contains("KotlinCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "1.8")
            } catch (e: Exception) {
                // Ignorar si no se puede configurar la propiedad
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
