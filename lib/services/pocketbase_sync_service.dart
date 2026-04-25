import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../models/appointment.dart';
import '../models/provider.dart';
import '../models/app_settings.dart';
import '../models/cliente.dart';
import '../models/cuenta_corriente.dart';
import '../models/movimiento_cuenta.dart';

/// Reemplazo de Google Drive backup por sync a PocketBase self-hosted.
///
/// Ventajas vs Drive:
/// - Sin OAuth flow (login simple email/password una sola vez)
/// - Sin costo (servidor propio Oracle Cloud)
/// - Versionado: cada sync crea un record nuevo (no sobrescribe)
/// - Sin dependencia de SDK de Google
///
/// Storage: SQLite del PocketBase persistido en disco del VPS.
/// Endpoint: configurable via `PocketBaseSyncService.serverUrl`.
enum SyncStatus {
  disconnected,
  connecting,
  authenticated,
  syncing,
  synced,
  syncFailed,
  authFailed,
}

class SyncBackupInfo {
  final String id;
  final DateTime created;
  final String? deviceInfo;
  final Map<String, dynamic>? stats;

  SyncBackupInfo({
    required this.id,
    required this.created,
    this.deviceInfo,
    this.stats,
  });
}

class PocketBaseSyncService {
  // Endpoint del servidor PocketBase (cambiable a futuro)
  static const String serverUrl = 'https://161-153-203-83.sslip.io';
  static const String _backupCollection = 'encantadas_backups';
  static const String _userCollection = 'encantadas_users';

  // localStorage keys (persisten credenciales y preferencias)
  static const String _emailKey = 'pb_sync_email';
  static const String _tokenKey = 'pb_sync_token';
  static const String _enabledKey = 'pb_sync_enabled';

  static PocketBaseSyncService? _instance;
  static PocketBaseSyncService get instance =>
      _instance ??= PocketBaseSyncService._();
  PocketBaseSyncService._();

  late final PocketBase _pb;
  bool _isAuthenticated = false;
  bool _isSyncing = false;
  bool _hasInternetConnection = false;
  bool _enabled = true;

  Timer? _syncTimer;
  Timer? _debounceTimer;
  String? _lastSyncedHash;

  final List<String> _pendingChanges = [];
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isAuthenticated => _isAuthenticated;
  bool get isSyncing => _isSyncing;
  bool get hasInternetConnection => _hasInternetConnection;
  bool get isEnabled => _enabled;
  int get pendingChangesCount => _pendingChanges.length;
  String? get currentEmail => html.window.localStorage[_emailKey];

  /// Inicializa el servicio: crea cliente PB, restaura sesion si existe,
  /// arranca listeners de conectividad.
  Future<void> initialize() async {
    _pb = PocketBase(serverUrl);

    // Restore enabled flag (default true)
    _enabled = (html.window.localStorage[_enabledKey] ?? 'true') == 'true';

    // Restore auth desde localStorage si existe
    final savedToken = html.window.localStorage[_tokenKey];
    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        // Decode token sin validar para reconstruir authStore
        _pb.authStore.save(savedToken, null);
        await _pb.collection(_userCollection).authRefresh();
        _isAuthenticated = _pb.authStore.isValid;
        if (_isAuthenticated) {
          _statusController.add(SyncStatus.authenticated);
        }
      } catch (e) {
        debugPrint('PB Sync: token restore failed: $e');
        _pb.authStore.clear();
        html.window.localStorage.remove(_tokenKey);
      }
    }

    await _checkInternetConnection();
    _setupConnectivityListener();

    if (_isAuthenticated && _enabled) {
      _startPeriodicSync();
    }
  }

  /// Login del usuario (email + password). Persiste el token para futuras sesiones.
  Future<bool> login(String email, String password) async {
    try {
      _statusController.add(SyncStatus.connecting);
      final result = await _pb
          .collection(_userCollection)
          .authWithPassword(email, password);

      if (result.token.isNotEmpty) {
        html.window.localStorage[_tokenKey] = result.token;
        html.window.localStorage[_emailKey] = email;
        _isAuthenticated = true;
        _statusController.add(SyncStatus.authenticated);

        if (_enabled) {
          _startPeriodicSync();
          // Sync inmediato tras primer login
          unawaited(_performSync());
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PB Sync: login failed: $e');
      _statusController.add(SyncStatus.authFailed);
      return false;
    }
  }

  /// Logout: limpia credenciales y para sync timer.
  Future<void> logout() async {
    _pb.authStore.clear();
    html.window.localStorage.remove(_tokenKey);
    html.window.localStorage.remove(_emailKey);
    _isAuthenticated = false;
    _syncTimer?.cancel();
    _debounceTimer?.cancel();
    _pendingChanges.clear();
    _statusController.add(SyncStatus.disconnected);
  }

  /// Habilita/deshabilita sync automatico (manteniendo auth).
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    html.window.localStorage[_enabledKey] = value.toString();
    if (value && _isAuthenticated) {
      _startPeriodicSync();
    } else {
      _syncTimer?.cancel();
      _debounceTimer?.cancel();
    }
  }

  /// Llamar cada vez que cambia data en la app — agenda un sync con debounce.
  void recordChange(String changeType) {
    if (!_enabled || !_isAuthenticated) return;
    _pendingChanges.add('${DateTime.now().toIso8601String()}: $changeType');
    _debounceSync();
  }

  /// Forzar sync inmediato (boton manual).
  Future<bool> forceSync() async {
    if (!_isAuthenticated) return false;
    return _performSync();
  }

  /// Listar backups del servidor (mas reciente primero).
  Future<List<SyncBackupInfo>> listBackups({int limit = 20}) async {
    if (!_isAuthenticated) return [];
    try {
      final result = await _pb.collection(_backupCollection).getList(
            page: 1,
            perPage: limit,
            sort: '-created',
            fields: 'id,created,device_info,stats',
          );
      return result.items.map((r) {
        return SyncBackupInfo(
          id: r.id,
          created: DateTime.tryParse(r.getStringValue('created')) ?? DateTime.now(),
          deviceInfo: r.getStringValue('device_info'),
          stats: r.get<Map<String, dynamic>?>('stats'),
        );
      }).toList();
    } catch (e) {
      debugPrint('PB Sync: list backups failed: $e');
      return [];
    }
  }

  /// Restaurar un backup especifico (sobrescribe TODO data local).
  Future<bool> restoreBackup(String backupId) async {
    if (!_isAuthenticated) return false;
    try {
      _statusController.add(SyncStatus.syncing);
      final record = await _pb.collection(_backupCollection).getOne(backupId);
      final data = record.get<Map<String, dynamic>>('data');
      await _restoreAllData(data);
      _statusController.add(SyncStatus.synced);
      return true;
    } catch (e) {
      debugPrint('PB Sync: restore failed: $e');
      _statusController.add(SyncStatus.syncFailed);
      return false;
    }
  }

  /// Eliminar un backup remoto.
  Future<bool> deleteBackup(String backupId) async {
    if (!_isAuthenticated) return false;
    try {
      await _pb.collection(_backupCollection).delete(backupId);
      return true;
    } catch (e) {
      debugPrint('PB Sync: delete failed: $e');
      return false;
    }
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    // Cada 5 min, verificar y sincronizar si hay cambios pendientes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_hasInternetConnection &&
          _isAuthenticated &&
          _pendingChanges.isNotEmpty) {
        _performSync();
      }
    });
  }

  void _debounceSync() {
    _debounceTimer?.cancel();
    // 30s de inactividad -> sync
    _debounceTimer = Timer(const Duration(seconds: 30), () {
      if (_hasInternetConnection && _isAuthenticated) {
        _performSync();
      }
    });
  }

  Future<bool> _performSync() async {
    if (_isSyncing || !_isAuthenticated || !_hasInternetConnection || !_enabled) {
      return false;
    }
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final backupData = await _collectAllData();
      final jsonString = jsonEncode(backupData);
      final dataHash = sha256.convert(utf8.encode(jsonString)).toString();

      // Skip si el hash no cambio (nada nuevo que sincronizar)
      if (dataHash == _lastSyncedHash) {
        _statusController.add(SyncStatus.synced);
        _pendingChanges.clear();
        return true;
      }

      final stats = {
        'products': (backupData['products'] as List).length,
        'transactions': (backupData['transactions'] as List).length,
        'appointments': (backupData['appointments'] as List).length,
        'providers': (backupData['providers'] as List).length,
        'clientes_cuenta': (backupData['clientes_cuenta'] as List).length,
        'cuentas_corrientes': (backupData['cuentas_corrientes'] as List).length,
        'movimientos_cuenta': (backupData['movimientos_cuenta'] as List).length,
      };

      final userId = _pb.authStore.record?.id;
      if (userId == null) {
        throw Exception('User ID not available');
      }

      await _pb.collection(_backupCollection).create(body: {
        'owner': userId,
        'data': backupData,
        'data_hash': dataHash,
        'version': '1.0.0',
        'device_info': _deviceInfo(),
        'stats': stats,
      });

      _lastSyncedHash = dataHash;
      _pendingChanges.clear();
      _statusController.add(SyncStatus.synced);
      return true;
    } catch (e) {
      // Si fue conflicto por unique hash (mismo backup ya subido), tratar como ok
      if (e.toString().contains('unique') || e.toString().contains('idx_encantadas_backups_owner_hash')) {
        _pendingChanges.clear();
        _statusController.add(SyncStatus.synced);
        return true;
      }
      debugPrint('PB Sync failed: $e');
      _statusController.add(SyncStatus.syncFailed);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Recolecta TODOS los datos de Hive en un Map JSON-serializable.
  /// Mismo schema que el export manual (compat con import).
  Future<Map<String, dynamic>> _collectAllData() async {
    final data = <String, dynamic>{};

    data['products'] = Hive.box<Product>('products')
        .values
        .map((p) => p.toJson())
        .toList();
    data['transactions'] = Hive.box<Transaction>('transactions')
        .values
        .map((t) => t.toJson())
        .toList();
    data['appointments'] = Hive.box<Appointment>('appointments')
        .values
        .map((a) => a.toJson())
        .toList();
    data['providers'] = Hive.box<Provider>('providers')
        .values
        .map((p) => p.toJson())
        .toList();

    final settingsBox = Hive.box<AppSettings>('settings');
    if (settingsBox.isNotEmpty) {
      data['settings'] = settingsBox.values.first.toJson();
    }

    data['clientes_cuenta'] = Hive.box<Cliente>('clientes_cuenta')
        .values
        .map((c) => c.toJson())
        .toList();
    data['cuentas_corrientes'] = Hive.box<CuentaCorriente>('cuentas_corrientes')
        .values
        .map((c) => c.toJson())
        .toList();
    data['movimientos_cuenta'] =
        Hive.box<MovimientoCuenta>('movimientos_cuenta')
            .values
            .map((m) => m.toJson())
            .toList();

    data['metadata'] = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'device': _deviceInfo(),
    };

    return data;
  }

  /// Restaura TODO el data desde un backup remoto. Limpia primero las boxes.
  Future<void> _restoreAllData(Map<String, dynamic> data) async {
    await Hive.box<Product>('products').clear();
    await Hive.box<Transaction>('transactions').clear();
    await Hive.box<Appointment>('appointments').clear();
    await Hive.box<Provider>('providers').clear();
    await Hive.box<AppSettings>('settings').clear();
    await Hive.box<Cliente>('clientes_cuenta').clear();
    await Hive.box<CuentaCorriente>('cuentas_corrientes').clear();
    await Hive.box<MovimientoCuenta>('movimientos_cuenta').clear();

    if (data['products'] != null) {
      final box = Hive.box<Product>('products');
      for (final j in data['products']) {
        await box.add(Product.fromJson(j));
      }
    }
    if (data['transactions'] != null) {
      final box = Hive.box<Transaction>('transactions');
      for (final j in data['transactions']) {
        await box.add(Transaction.fromJson(j));
      }
    }
    if (data['appointments'] != null) {
      final box = Hive.box<Appointment>('appointments');
      for (final j in data['appointments']) {
        await box.add(Appointment.fromJson(j));
      }
    }
    if (data['providers'] != null) {
      final box = Hive.box<Provider>('providers');
      for (final j in data['providers']) {
        await box.add(Provider.fromJson(j));
      }
    }
    if (data['settings'] != null) {
      await Hive.box<AppSettings>('settings').add(
        AppSettings.fromJson(data['settings']),
      );
    }
    if (data['clientes_cuenta'] != null) {
      final box = Hive.box<Cliente>('clientes_cuenta');
      for (final j in data['clientes_cuenta']) {
        await box.add(Cliente.fromJson(j));
      }
    }
    if (data['cuentas_corrientes'] != null) {
      final box = Hive.box<CuentaCorriente>('cuentas_corrientes');
      for (final j in data['cuentas_corrientes']) {
        await box.add(CuentaCorriente.fromJson(j));
      }
    }
    if (data['movimientos_cuenta'] != null) {
      final box = Hive.box<MovimientoCuenta>('movimientos_cuenta');
      for (final j in data['movimientos_cuenta']) {
        await box.add(MovimientoCuenta.fromJson(j));
      }
    }
  }

  String _deviceInfo() {
    try {
      final ua = html.window.navigator.userAgent;
      // Extraer solo la parte util sin info sensible
      final platform = html.window.navigator.platform ?? 'unknown';
      return '$platform | ${ua.substring(0, ua.length > 80 ? 80 : ua.length)}';
    } catch (_) {
      return 'web-client';
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _hasInternetConnection = !result.contains(ConnectivityResult.none);
      _connectionController.add(_hasInternetConnection);
    } catch (_) {
      _hasInternetConnection = true; // Asume online si no se puede chequear
    }
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((results) {
      final newState = !results.contains(ConnectivityResult.none);
      if (newState != _hasInternetConnection) {
        _hasInternetConnection = newState;
        _connectionController.add(_hasInternetConnection);
        // Si volvio la conexion y hay pendientes, sincronizar
        if (newState && _isAuthenticated && _pendingChanges.isNotEmpty) {
          _performSync();
        }
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
    _debounceTimer?.cancel();
    _statusController.close();
    _connectionController.close();
  }
}

/// Helper para hacer fire-and-forget de un Future.
void unawaited(Future<void> f) {
  f.catchError((e) {
    debugPrint('Unawaited future failed: $e');
  });
}
