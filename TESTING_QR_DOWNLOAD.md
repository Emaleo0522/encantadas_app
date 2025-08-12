# 🧪 Guía de Prueba: Descarga de Códigos QR

## ✅ Estado de Compilación
- **Análisis de código**: ✅ Sin errores críticos
- **Compilación web**: ✅ Exitosa
- **Dependencias**: ✅ Todas instaladas correctamente

## 🎯 Cómo Probar la Funcionalidad

### **Prerequisitos para Testing Completo:**
- Dispositivo Android con permisos de almacenamiento
- O emulador Android configurado
- O dispositivo iOS

### **Pasos de Prueba:**

#### **1. Ejecutar la Aplicación**
```bash
# Para Android (si está configurado)
flutter run -d android

# Para iOS (si está configurado)  
flutter run -d ios

# Para web (limitado - sin descarga real)
flutter run -d web-server
```

#### **2. Navegar a la Funcionalidad QR**
1. Abrir la aplicación Encantadas
2. Ir a la pestaña **"Stock"** (3era pestaña)
3. Si no hay productos, agregar uno con el botón **"+"**
4. En cualquier producto existente, hacer clic en el menú **"⋮"**
5. Seleccionar **"Ver código QR"**

#### **3. Probar Descarga**
1. En el diálogo del QR, hacer clic en **"Descargar"**
2. **Primera vez**: El sistema solicitará permisos de almacenamiento
3. **Conceder permisos** cuando se soliciten
4. El botón mostrará **"Descargando..."** con spinner
5. Al completarse, aparecerá mensaje de éxito con nombre del archivo

#### **4. Verificar Resultado**
- **Android**: Buscar en `/storage/emulated/0/Download/QR_[CODIGO].png`
- **iOS**: El archivo se guarda en documentos de la app
- **Windows**: Carpeta `Descargas` del usuario

## 🔍 Casos de Prueba Específicos

### **Caso 1: Descarga Exitosa**
- **Acción**: Descargar QR de producto válido
- **Resultado Esperado**: 
  - ✅ Archivo PNG guardado
  - ✅ SnackBar verde con confirmación
  - ✅ Nombre: `QR_P-001.png` (ejemplo)

### **Caso 2: Sin Permisos**
- **Acción**: Denegar permisos de almacenamiento
- **Resultado Esperado**:
  - ❌ SnackBar rojo con error
  - 🔧 Botón "Configurar" para abrir settings

### **Caso 3: Código Inválido**
- **Acción**: Intentar generar QR con código vacío
- **Resultado Esperado**:
  - ❌ Diálogo de error antes de mostrar QR
  - 📝 Mensaje: "Sin código de producto"

### **Caso 4: Archivos Duplicados**
- **Acción**: Descargar mismo QR múltiples veces
- **Resultado Esperado**:
  - ✅ Archivos únicos: `QR_P-001.png`, `QR_P-001_1.png`, etc.
  - ✅ No sobrescribe archivos existentes

## 📱 Testing por Plataforma

### **Android**
```bash
# Verificar permisos en AndroidManifest.xml
grep -A 10 "permission" android/app/src/main/AndroidManifest.xml

# Ejecutar en dispositivo/emulador
flutter run -d android

# Verificar archivo descargado
adb shell ls /storage/emulated/0/Download/QR_*.png
```

### **iOS** 
```bash
# Ejecutar en simulador/dispositivo
flutter run -d ios

# Los archivos se guardan en sandbox de la app
# Verificar a través de iTunes/Finder
```

### **Web (Limitado)**
```bash
# Solo para verificar UI y validaciones
flutter run -d web-server

# Nota: La descarga real no funciona en web
# Pero se puede probar la interfaz y validaciones
```

## 🐛 Debug y Solución de Problemas

### **Problemas Comunes:**

#### **1. "No se pudo capturar imagen"**
- **Causa**: RepaintBoundary no inicializado
- **Solución**: Esperar que el widget se renderice completamente

#### **2. "Se requieren permisos"**
- **Causa**: Permisos de almacenamiento denegados
- **Solución**: Conceder permisos o usar botón "Configurar"

#### **3. "No se pudo guardar imagen"**
- **Causa**: Directorio no accesible o sin espacio
- **Solución**: Verificar permisos y espacio disponible

### **Logs de Debug:**
Los mensajes de debug aparecen en consola con prefijos:
```
Error capturando widget como imagen: [detalles]
Error solicitando permisos: [detalles]  
Error guardando imagen: [detalles]
Imagen QR guardada en: [ruta completa]
```

## 🎨 Verificación Visual

### **Contenido del QR Generado:**
El archivo PNG descargado debe contener:
- ✅ **Nombre del producto** (parte superior)
- ✅ **Código QR** centrado y legible
- ✅ **Código del producto** (parte inferior)
- ✅ **Fondo blanco** para máximo contraste
- ✅ **Resolución alta** (600x600+ píxeles aprox.)

### **Calidad Esperada:**
- 📐 **Dimensiones**: ~300x400 píxeles
- 🎯 **Resolución**: 3x pixel ratio (alta calidad)
- 🎨 **Formato**: PNG con transparencia
- 📝 **Legibilidad**: Texto claro y QR escaneable

## ⚡ Performance Testing

### **Métricas a Verificar:**
- ⏱️ **Tiempo de captura**: < 2 segundos
- 💾 **Tamaño de archivo**: 20-100 KB típico
- 🔄 **Memoria**: Sin memory leaks
- 📱 **Responsividad**: UI no se congela

## 🚀 Próximos Pasos

Si todas las pruebas pasan exitosamente:
1. ✅ **La funcionalidad está lista para producción**
2. 📱 **Se puede desplegar en tiendas de aplicaciones**
3. 👥 **Realizar testing con usuarios reales**
4. 📊 **Monitorear métricas de uso y errores**

---

## 📞 Soporte

Si encuentras problemas durante el testing:
1. Verificar logs en consola Flutter
2. Revisar permisos de la aplicación
3. Confirmar que el dispositivo tiene espacio disponible
4. Probar en diferentes dispositivos/plataformas

**Estado**: ✅ Funcionalidad completamente implementada y lista para testing
**Última actualización**: $(date)