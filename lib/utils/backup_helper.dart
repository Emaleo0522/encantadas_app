import '../services/backup_service.dart';

/// Helper class to standardize backup change recording across the app
class BackupHelper {
  // Private constructor to prevent instantiation
  BackupHelper._();

  /// Record a product-related change
  static void recordProductChange(String action, String productName) {
    final message = '$action: $productName';
    BackupService.instance.recordChange('producto: $message');
    print('📦 Producto registrado para backup: $message');
  }

  /// Record a transaction-related change
  static void recordTransactionChange(String action, double amount, {String? details}) {
    final message = '$action: \$${amount.toStringAsFixed(2)}${details != null ? ' - $details' : ''}';
    BackupService.instance.recordChange('transaccion: $message');
    print('💰 Transacción registrada para backup: $message');
  }

  /// Record an appointment-related change
  static void recordAppointmentChange(String action, String clientName, DateTime date) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final message = '$action: $clientName - $dateStr';
    BackupService.instance.recordChange('turno: $message');
    print('📅 Turno registrado para backup: $message');
  }

  /// Record a provider-related change
  static void recordProviderChange(String action, String providerName) {
    final message = '$action: $providerName';
    BackupService.instance.recordChange('proveedor: $message');
    print('🏭 Proveedor registrado para backup: $message');
  }

  /// Record a supplier-related change
  static void recordSupplierChange(String action, String supplierName) {
    final message = '$action: $supplierName';
    BackupService.instance.recordChange('supplier: $message');
    print('📋 Supplier registrado para backup: $message');
  }

  /// Record settings-related changes
  static void recordSettingsChange(String action) {
    BackupService.instance.recordChange('configuracion: $action');
    print('⚙️ Configuración registrada para backup: $action');
  }

  /// Record generic changes
  static void recordGenericChange(String category, String action) {
    BackupService.instance.recordChange('$category: $action');
    print('🔄 Cambio registrado para backup: $category - $action');
  }
}