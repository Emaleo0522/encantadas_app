# 📱 Instrucciones para Crear APK de Encantadas App

## Método 1: APK Directo con Flutter (Recomendado)

### Requisitos previos:
1. **Instalar Flutter SDK**: https://docs.flutter.dev/get-started/install
2. **Instalar Android SDK**: https://developer.android.com/studio
3. **Configurar variables de entorno**

### Pasos:

#### 1. Instalar Flutter
```bash
# En Windows
# Descargar Flutter SDK desde: https://docs.flutter.dev/get-started/install/windows

# En Linux/Mac
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.8-stable.tar.xz
tar xf flutter_linux_3.32.8-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

#### 2. Instalar Android Studio
- Descargar desde: https://developer.android.com/studio
- Instalar Android SDK a través de Android Studio
- Aceptar licencias: `flutter doctor --android-licenses`

#### 3. Generar APK
```bash
# Navegar al directorio del proyecto
cd /ruta/a/encantadas_app

# Verificar configuración
flutter doctor

# Construir APK
flutter build apk --release

# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

## Método 2: Usar Android Studio Directo

### Pasos:
1. Abrir Android Studio
2. Abrir el proyecto Encantadas App
3. Ir a Build → Generate Signed Bundle / APK
4. Seleccionar APK
5. Crear o usar keystore existente
6. Build Release APK

## Método 3: APK Web (PWA)

### Para dispositivos que soporten PWA:
1. Abrir Chrome en tu celular
2. Ir a: `http://[tu_ip]:8080` (donde está corriendo la app web)
3. Tocar el menú (3 puntos)
4. Seleccionar "Instalar app" o "Agregar a pantalla de inicio"

## Archivos Importantes Generados:

- ✅ **Web App**: `/build/web/` (listo para servidor)
- ✅ **Manifest PWA**: Configurado correctamente
- ✅ **Service Worker**: Generado automáticamente
- ✅ **Iconos**: Incluidos en diferentes tamaños

## Para Compartir la App:

### Opción A: APK Directo
- Generar APK con Flutter
- Compartir archivo `.apk`
- Habilitar "Fuentes desconocidas" en Android

### Opción B: PWA Web
- Subir carpeta `/build/web/` a servidor web
- Compartir URL
- Los usuarios pueden "instalar" desde el navegador

## Próximos Pasos Recomendados:

1. **Generar APK localmente** usando Flutter
2. **Firmar APK** para distribución
3. **Subir a Play Store** (opcional, requiere cuenta de desarrollador)
4. **Configurar actualizaciones automáticas**

## Soporte de Dispositivos:
- ✅ Android 5.0+ (API level 21+)
- ✅ iOS 10+ (si usas Xcode para build iOS)
- ✅ Web browsers (Chrome, Firefox, Safari, Edge)

## Notas Importantes:
- La app usa **almacenamiento local** (Hive)
- **No requiere conexión a internet** una vez instalada
- **Todos los datos se guardan en el dispositivo**
- **No hay sincronización entre dispositivos** (por diseño)

¡La app está completamente funcional y lista para usar! 🎉