import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late BackupService _backupService;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.instance;
    _backupService = BackupService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Box<AppSettings>>(
        valueListenable: Hive.box<AppSettings>('settings').listenable(),
        builder: (context, box, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuraciones',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Personaliza tu experiencia',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // QR Settings Section
              _buildSectionCard(
                title: 'Código QR',
                icon: Icons.qr_code,
                children: [
                  _buildSwitchTile(
                    title: 'Modo Automático QR',
                    subtitle: _settings.autoQRModeDescription,
                    icon: Icons.flash_auto,
                    value: _settings.autoQRMode,
                    onChanged: (value) async {
                      setState(() {
                        _settings.autoQRMode = value;
                      });
                      await _settings.saveSettings();
                      
                      // Show confirmation
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  value ? Icons.flash_auto : Icons.touch_app,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  value 
                                      ? 'Modo automático activado'
                                      : 'Modo manual activado',
                                ),
                              ],
                            ),
                            backgroundColor: value ? Colors.green : Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const Divider(),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _settings.autoQRMode 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _settings.autoQRMode 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _settings.autoQRMode ? Icons.info : Icons.warning,
                              color: _settings.autoQRMode ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _settings.autoQRMode ? 'Modo Automático' : 'Modo Manual',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _settings.autoQRMode 
                                    ? Colors.green[700] 
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _settings.autoQRMode
                              ? '• Al escanear QR, se procesará automáticamente\n• Descuenta stock inmediatamente\n• Registra venta sin confirmación\n• Ideal para ventas rápidas'
                              : '• Al escanear QR, mostrará pantalla de confirmación\n• Puedes modificar precio o cantidad\n• Requiere confirmación para procesar\n• Mayor control en cada venta',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Manual Backup Section
              _buildManualBackupSection(),
              
              const SizedBox(height: 16),
              
              // Backup Settings Section
              _buildBackupSection(),
              
              const SizedBox(height: 16),
              
              // General Settings Section
              _buildSectionCard(
                title: 'General',
                icon: Icons.tune,
                children: [
                  _buildSwitchTile(
                    title: 'Diálogos de Confirmación',
                    subtitle: 'Mostrar confirmaciones para acciones importantes',
                    icon: Icons.help_outline,
                    value: _settings.showConfirmationDialogs,
                    onChanged: (value) async {
                      setState(() {
                        _settings.showConfirmationDialogs = value;
                      });
                      await _settings.saveSettings();
                    },
                  ),
                  
                  _buildSwitchTile(
                    title: 'Notificaciones',
                    subtitle: 'Recibir notificaciones de la app',
                    icon: Icons.notifications,
                    value: _settings.enableNotifications,
                    onChanged: (value) async {
                      setState(() {
                        _settings.enableNotifications = value;
                      });
                      await _settings.saveSettings();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tip: Modo Automático QR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Con el modo automático activado, puedes escanear códigos QR desde la cámara de tu teléfono y la app procesará la venta automáticamente.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBackupSection() {
    return StreamBuilder<BackupStatus>(
      stream: _backupService.statusStream,
      builder: (context, statusSnapshot) {
        return StreamBuilder<bool>(
          stream: _backupService.connectionStream,
          builder: (context, connectionSnapshot) {
            final isConnected = connectionSnapshot.data ?? false;
            final status = statusSnapshot.data ?? BackupStatus.disconnected;
            
            return _buildSectionCard(
              title: 'Backup Automático',
              icon: Icons.cloud_sync,
              children: [
                if (!_backupService.isConfigured) ...[
                  // Not configured - show instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Backup no configurado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para habilitar el backup automático:\n• Configura Google Cloud Console\n• Actualiza el Client ID en google_drive_config.js\n• Rebuild la aplicación',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else if (!_backupService.isAuthenticated) ...[
                  // Not authenticated - show setup
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_off, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Sin backup automático',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Conecta con Google Drive para:\n• Nunca perder tus datos\n• Sincronizar entre dispositivos\n• Backup automático invisible',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: status == BackupStatus.authenticating ? null : _authenticateWithGoogleDrive,
                            icon: status == BackupStatus.authenticating 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud),
                            label: Text(status == BackupStatus.authenticating 
                                ? 'Conectando...' 
                                : 'Conectar Google Drive'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Authenticated - show status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isConnected ? Icons.cloud_done : Icons.cloud_off,
                              color: isConnected ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isConnected ? 'Backup activo' : 'Sin conexión',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isConnected ? Colors.green[700] : Colors.orange[700],
                                ),
                              ),
                            ),
                            _buildStatusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected 
                              ? 'Tus datos se guardan automáticamente en Google Drive'
                              : 'Sin internet. Cambios se guardarán cuando vuelva la conexión',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        if (_backupService.pendingChangesCount > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_backupService.pendingChangesCount} cambios pendientes',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showBackupInfo,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Ver info'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: status == BackupStatus.syncing ? null : _forcSync,
                          icon: status == BackupStatus.syncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: Text(status == BackupStatus.syncing 
                              ? 'Sincronizando...' 
                              : 'Sincronizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Disconnect button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _disconnectGoogleDrive,
                      icon: const Icon(Icons.cloud_off, color: Colors.red),
                      label: const Text('Desconectar Google Drive', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(BackupStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BackupStatus.synced:
        color = Colors.green;
        text = 'Sincronizado';
        icon = Icons.check_circle;
        break;
      case BackupStatus.syncing:
        color = Colors.blue;
        text = 'Sincronizando';
        icon = Icons.sync;
        break;
      case BackupStatus.syncFailed:
        color = Colors.red;
        text = 'Error';
        icon = Icons.error;
        break;
      case BackupStatus.authenticating:
        color = Colors.orange;
        text = 'Conectando';
        icon = Icons.login;
        break;
      default:
        color = Colors.grey;
        text = 'Desconectado';
        icon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithGoogleDrive() async {
    final success = await _backupService.authenticate();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('¡Conectado con Google Drive! Backup automático activado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Error al conectar. Inténtalo de nuevo'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Desconectar Google Drive'),
          ],
        ),
        content: const Text(
          '¿Estás seguro? Se desactivará el backup automático. '
          'Tus datos actuales permanecerán en el dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _backupService.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Google Drive desconectado'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _forcSync() async {
    await _backupService.forcSync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.sync, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Sincronización completada'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackupInfo() async {
    final backupInfo = await _backupService.getBackupInfo();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.blue),
            SizedBox(width: 8),
            Text('Información de Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (backupInfo != null) ...[
              _buildInfoRow('Archivo:', backupInfo.fileName),
              _buildInfoRow('Última actualización:', backupInfo.formattedDate),
              _buildInfoRow('Tamaño:', backupInfo.formattedSize),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tus datos están seguros en Google Drive',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text('No hay información de backup disponible.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (backupInfo != null) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _restoreFromBackup();
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Restaurar datos'),
          ],
        ),
        content: const Text(
          '¿Estás seguro? Esta acción reemplazará TODOS los datos actuales '
          'con los datos del backup de Google Drive. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _backupService.restoreFromGoogleDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(success 
                    ? 'Datos restaurados correctamente' 
                    : 'Error al restaurar datos'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildManualBackupSection() {
    return _buildSectionCard(
      title: 'Backup Manual',
      icon: Icons.file_download,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Backup de Seguridad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Exporta e importa tus datos manualmente para mayor seguridad',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Current Data Summary
        FutureBuilder<Map<String, int>>(
          future: _backupService.getCurrentDataSummary(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Actuales:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _buildDataChip('Productos', data['products'] ?? 0),
                      _buildDataChip('Ventas', data['transactions'] ?? 0),
                      _buildDataChip('Citas', data['appointments'] ?? 0),
                      _buildDataChip('Clientes', data['clientes_cuenta'] ?? 0),
                      _buildDataChip('Proveedores', data['providers'] ?? 0),
                      _buildDataChip('Cuentas', data['cuentas_corrientes'] ?? 0),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportDataManually,
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _importDataManually,
                icon: const Icon(Icons.file_upload),
                label: const Text('Importar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.amber[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Exporta regularmente para tener respaldos locales',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataChip(String label, int count) {
    return Chip(
      label: Text(
        '$label: $count',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: Colors.blue.withOpacity(0.1),
      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
    );
  }

  Future<void> _exportDataManually() async {
    try {
      await _backupService.exportDataManually();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Datos exportados exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al exportar: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importDataManually() async {
    if (kIsWeb) {
      // For web: use file input
      final input = html.FileUploadInputElement()
        ..accept = '.json'
        ..click();
      
      input.onChange.listen((e) async {
        final files = input.files;
        if (files?.isEmpty ?? true) return;
        
        final file = files!.first;
        final reader = html.FileReader();
        
        reader.onLoadEnd.listen((e) async {
          try {
            final content = reader.result as String;
            await _processImport(content);
          } catch (e) {
            _showImportError('Error reading file: $e');
          }
        });
        
        reader.readAsText(file);
      });
    } else {
      // For mobile: would need file_picker package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import function needs file_picker package for mobile'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _processImport(String jsonContent) async {
    try {
      // Show confirmation dialog with preview
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => _buildImportConfirmationDialog(jsonContent),
      );
      
      if (shouldImport == true) {
        final success = await _backupService.importDataManually(jsonContent);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(success 
                    ? '¡Datos importados exitosamente!' 
                    : 'Error al importar datos'),
                ],
              ),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      _showImportError('Error processing import: $e');
    }
  }

  Widget _buildImportConfirmationDialog(String jsonContent) {
    try {
      final data = const JsonDecoder().convert(jsonContent) as Map<String, dynamic>;
      
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Importación'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ ATENCIÓN: Esta acción reemplazará TODOS los datos actuales.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Datos a importar:'),
              const SizedBox(height: 8),
              _buildImportDataPreview(data),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Importar'),
          ),
        ],
      );
    } catch (e) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text('Archivo JSON inválido: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }
  }

  Widget _buildImportDataPreview(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewRow('📦 Productos', data['products']?.length ?? 0),
          _buildPreviewRow('💰 Transacciones', data['transactions']?.length ?? 0),
          _buildPreviewRow('📅 Citas', data['appointments']?.length ?? 0),
          _buildPreviewRow('🏪 Proveedores', data['providers']?.length ?? 0),
          _buildPreviewRow('👥 Clientes', data['clientes_cuenta']?.length ?? 0),
          _buildPreviewRow('💳 Cuentas', data['cuentas_corrientes']?.length ?? 0),
          if (data['metadata']?['timestamp'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '📅 Backup del: ${data['metadata']['timestamp']}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showImportError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}