# 💄 Encantadas App

Una aplicación Flutter completa para la gestión integral de negocios de belleza y estética.

## 📱 Descripción

**Encantadas App** es una solución completa para la gestión de negocios de belleza que incluye control de inventario, sistema de ventas, gestión de turnos, cuentas corrientes y backup automático en la nube.

## ✨ Funcionalidades Principales

### 🏠 **Dashboard**
- Panel principal con estadísticas del negocio
- Alertas de cuentas morosas
- Resumen de actividad reciente
- Accesos rápidos a funciones principales

### 📦 **Gestión de Stock/Inventario**
- Control completo de productos (ropa, uñas, bijouterie)
- Generación automática de códigos QR
- Gestión por categorías con colores y emojis
- Control de stock bajo y alertas
- Integración con proveedores

### 💰 **Sistema de Ventas**
- Registro de ventas de productos y servicios
- **Procesamiento de QR automático** para ventas rápidas
- Descuento automático de stock
- Historial detallado de transacciones

### 📅 **Gestión de Turnos**
- Programación de citas con clientes
- Gestión de servicios de belleza
- Notificaciones locales

### 👥 **Sistema de Cuenta Corriente (Fiado)**
- Gestión completa de clientes con **edición de datos**
- Cuentas corrientes con límites de crédito
- Registro de cargos y pagos
- Alertas de cuentas morosas (>30 días)
- Integración con WhatsApp

### 📊 **Balance y Reportes**
- Estadísticas de ventas e ingresos
- Gráficos visuales para análisis
- Reportes por períodos de tiempo

### 🏭 **Gestión de Proveedores**
- Registro de proveedores y suppliers
- Asociación con productos
- Estadísticas por proveedor

### ☁️ **Backup Automático Google Drive**
- **Sincronización automática completa** de todos los datos
- Backup cada 30 segundos tras cambios + cada 5 minutos
- Restauración completa de datos
- **Registro automático de TODOS los cambios** (productos, ventas, turnos, etc.)

## 🚀 Tecnologías

- **Flutter** 3.32.8 (Web, Android, iOS, Desktop)
- **Hive** - Base de datos local NoSQL
- **Google Drive API** - Backup en la nube
- **Material Design** - UI/UX moderna
- **QR Code** - Generación y procesamiento

## 🔧 Configuración

### Prerrequisitos
- Flutter SDK 3.32.8+
- Dart 3.8.1+

### Instalación
```bash
# Clonar repositorio
git clone https://github.com/usuario/encantadas_app.git
cd encantadas_app

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run -d web-server --web-port=8080
```

### Build para Producción
```bash
# Build web
flutter build web --release

# El build estará en build/web/
```

### Configuración de Google Drive (Opcional)
Para habilitar el backup automático:

1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Crea un proyecto y habilita "Google Drive API"
3. Crea "OAuth 2.0 Client ID" para aplicación web
4. Agrega tu dominio a "Authorized JavaScript origins"
5. Actualiza `web/google_drive_config.js` con tu Client ID

## 📁 Estructura del Proyecto

```
lib/
├── models/          # Modelos de datos (Hive)
├── screens/         # Pantallas principales
├── widgets/         # Widgets personalizados
├── services/        # Lógica de negocio
└── utils/           # Utilidades y helpers

web/
├── index.html       # HTML principal
└── google_drive_config.js  # Configuración backup
```

## 🔒 Características de Seguridad

- Validaciones robustas en todos los formularios
- Backup automático encriptado
- Headers de seguridad configurados
- Manejo seguro de archivos temporales

## 🌐 Deployment

### Netlify
1. Ejecuta `flutter build web --release`
2. Sube la carpeta `build/web/` o usa el ZIP incluido
3. Configura redirects para SPA

### Build Incluido
El proyecto incluye `encantadas_COMPLETE_BACKUP_[fecha].zip` listo para deployment.

## 📈 Estado del Proyecto

- ✅ **Versión estable**: Lista para producción
- ✅ **Backup completo**: Todos los módulos sincronizados
- ✅ **Multi-plataforma**: Web, Android, iOS, Desktop
- ✅ **Sistema QR**: Generación y procesamiento completo
- ✅ **Edición de clientes**: Funcionalidad completa

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Contacto

- **Proyecto**: Encantadas App
- **Descripción**: Sistema de gestión para negocios de belleza
- **Tecnología**: Flutter + Google Drive API

---

*Desarrollado con ❤️ usando Flutter*