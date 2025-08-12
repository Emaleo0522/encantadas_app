/* 
=== CONFIGURACIÓN DE GOOGLE DRIVE BACKUP ===

Para habilitar el backup automático, sigue estos pasos:

1. Ve a Google Cloud Console: https://console.cloud.google.com
2. Crea un proyecto nuevo o selecciona uno existente
3. En "APIs & Services" > "Library", habilita "Google Drive API"
4. En "APIs & Services" > "Credentials", crea "OAuth 2.0 Client ID"
5. Selecciona "Web application"
6. En "Authorized JavaScript origins" agrega:
   - http://localhost:8080 (para desarrollo)
   - https://tu-app.netlify.app (tu dominio de producción)
7. Copia el Client ID generado y reemplázalo abajo

IMPORTANTE: 
- Sin configurar esto, el backup automático no funcionará
- La app seguirá funcionando normalmente en modo local
- Los usuarios verán la opción de configurar backup en Settings
*/

window.googleDriveConfig = {
  // ✅ Client ID configurado y funcionando
  clientId: '98755823898-3pshprdpp54nhecr0h7q00sj92kmv2o9.apps.googleusercontent.com',
  
  // ✅ Estos scopes son correctos - actualizados para acceso completo
  scopes: [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata'
  ],
  
  // ✅ Discovery docs - no cambiar
  discoveryDocs: [
    'https://www.googleapis.com/discovery/v1/apis/drive/v3/rest'
  ]
};

// Debug: Confirmar que la configuración se cargó
console.log('Google Drive Config loaded:', window.googleDriveConfig);
console.log('Client ID:', window.googleDriveConfig.clientId);

// Función para inicializar Google API
window.initGoogleDriveAPI = function() {
  return new Promise((resolve, reject) => {
    if (typeof gapi === 'undefined') {
      reject(new Error('Google API no está cargado'));
      return;
    }
    
    gapi.load('auth2', () => {
      gapi.auth2.init({
        client_id: window.googleDriveConfig.clientId,
        scope: window.googleDriveConfig.scopes.join(' ')
      }).then(() => {
        console.log('Google Drive API inicializada');
        resolve();
      }).catch(reject);
    });
  });
};
