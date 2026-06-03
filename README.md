# 🎵 Tocadiscos.pro 💿 — TocaNexxos.pro

[![Flutter Version](https://img.shields.io/badge/Flutter-%E2%9C%93-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Clean%20Architecture-Feature--First-orange?style=for-the-badge)](https://cleanarchitecture.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge)](https://android.com)
[![Branding](https://img.shields.io/badge/Branding-TocaNexxos.pro-D81B60?style=for-the-badge)](#)

Un reproductor de música local elegante con sabor analógico y diseño retro-moderno inspirado en tocadiscos de vinilo clásicos. **Tocadiscos.pro** combina la calidez y el estilo de los LP vintage con la potencia de la tecnología moderna móvil.

---

## 🎨 Estética & Diseño Premium

- **Branding Visual (TocaNexxos.pro):** Un logotipo interior vibrante con un tocadiscos turquesa (`#33C2D2`), centro de vinilo rosa (`#D81B60`) y brazo metálico de precisión.
- **Splash Screen Dinámica:** Animación pulsante del plato del tocadiscos durante el inicio de la app.
- **Rotación de Vinilo Realista:** Disco que gira a 33 RPM reales cuando la música está sonando y se detiene suavemente al pausar.
- **Temas Inteligentes:** Selector táctil para alternar instantáneamente entre temas **Claro**, **Oscuro Moderno** y **AMOLED Puro** (para ahorro de batería en pantallas OLED).

---

## ✨ Características Principales

📁 **Explorador por Carpetas:** Agrupación automática e inteligente de tus canciones locales según sus directorios físicos en el almacenamiento.  
🔍 **Búsqueda Avanzada:** Barra de búsqueda en tiempo real dentro de tu biblioteca general, favoritos y por carpetas individuales.  
📝 **Listas de Reproducción Personalizadas:** Crea, elimina y organiza tus canciones en listas ilimitadas, persistidas localmente en el dispositivo.  
💖 **Colección de Favoritos:** Un botón de corazón dedicado para guardar y acceder instantáneamente a tus canciones preferidas de forma persistente.  
🎛️ **Ecualizador Nativo de 5 Bandas:** Acceso directo al ecualizador nativo de Android (`AndroidEqualizer`) con preajustes para Rock, Pop, Heavy Metal, Jazz, Flat y modo manual "Personalizado".  
🔄 **Sincronización en Segundo Plano:** Control de reproducción y visualización de carátulas en la pantalla de bloqueo y barra de estado a través de `audio_service`.  
🏠 **Home Widget:** Widget nativo interactivo para controlar la música directamente desde la pantalla de inicio del móvil.

---

## 🏗️ Arquitectura del Software

Este proyecto aplica **Clean Architecture** (Arquitectura Limpia) con una organización estructurada orientada a características (**Feature-First**):

```text
lib/
├── core/                       # Núcleo de la aplicación
│   ├── di/                     # Inyección de dependencias (Riverpod)
│   ├── permission/             # Lógica de permisos de almacenamiento
│   └── theme/                  # Sistema de temas (Claro, Oscuro, AMOLED)
└── features/                   # Módulos del negocio
    ├── home_widget/            # Integración nativa de widgets de pantalla
    ├── library/                # Música local, Carpetas, Favoritos y Playlists
    │   ├── data/               # Orígenes de datos y repositorios
    │   ├── domain/             # Entidades y lógica del negocio
    │   └── presentation/       # Vistas (screens), widgets y proveedores (providers)
    └── player/                 # Motor de audio y controles físicos del vinilo
```

---

## 🚀 Requisitos de Instalación

1. Asegúrate de tener instalado el SDK de [Flutter](https://docs.flutter.dev/get-started/install) (versión estable).
2. Clona este repositorio en tu computadora.
3. Conecta un dispositivo móvil o emulador.
4. Abre la consola y ejecuta los siguientes comandos:

```bash
# Descargar dependencias
flutter pub get

# Generar iconos nativos de lanzamiento
flutter pub run flutter_launcher_icons

# Compilar y ejecutar la aplicación
flutter run
```

---

## 🎁 Donaciones & Soporte

¿Te gusta este proyecto y quieres apoyar su desarrollo continuo? ¡Toda contribución nos ayuda a mantener el vinilo girando y a seguir creando software de calidad de código abierto! ☕💖

Puedes apoyarnos a través de las siguientes plataformas:

| Método de Donación | Enlace directo |
| :--- | :--- |
| **PayPal** | [paypal.me/JMSOLUTIONS8825](https://paypal.me/JMSOLUTIONS8825) |
| **Kofi** | [ko-fi.com/tocadexxos](https://ko-fi.com) |
| **Patreon** | [patreon.com/tocaNexxos](https://patreon.com) |

### 🪙 Direcciones de Criptomonedas:
- **Bitcoin (BTC):** `1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa`
- **Ethereum (ETH):** `0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe`
- **USDT (TRC-20):** `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t`

---

*Desarrollado con ❤️ por **JorgeAnalista** usando Flutter.*
