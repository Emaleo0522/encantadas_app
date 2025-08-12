import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cliente.dart';
import '../models/cuenta_corriente.dart';
import '../models/movimiento_cuenta.dart';
import 'backup_service.dart';

class CuentaCorrienteService {
  static CuentaCorrienteService? _instance;
  static CuentaCorrienteService get instance => _instance ??= CuentaCorrienteService._();
  
  CuentaCorrienteService._();

  // Boxes de Hive
  Box<Cliente> get _clientesBox => Hive.box<Cliente>('clientes_cuenta');
  Box<CuentaCorriente> get _cuentasBox => Hive.box<CuentaCorriente>('cuentas_corrientes');
  Box<MovimientoCuenta> get _movimientosBox => Hive.box<MovimientoCuenta>('movimientos_cuenta');

  /// GESTIÓN DE CLIENTES ///

  // Crear nuevo cliente
  Future<Cliente> crearCliente({
    required String nombre,
    required String apellido,
    String? telefono,
    String? direccion,
    String? email,
    String? documento,
    String? notas,
  }) async {
    final cliente = Cliente(
      nombre: nombre,
      apellido: apellido,
      telefono: telefono,
      direccion: direccion,
      email: email,
      documento: documento,
      fechaRegistro: DateTime.now(),
      notas: notas,
      activo: true,
    );

    await _clientesBox.add(cliente);
    _registrarCambio('Cliente creado: ${cliente.nombreCompleto}');
    return cliente;
  }

  // Obtener todos los clientes
  List<Cliente> obtenerClientes({bool soloActivos = true}) {
    final clientes = _clientesBox.values.toList();
    if (soloActivos) {
      return clientes.where((c) => c.activo).toList();
    }
    return clientes;
  }

  // Editar cliente existente
  Future<void> editarCliente(
    Cliente cliente, {
    required String nombre,
    required String apellido,
    String? telefono,
    String? direccion,
    String? email,
    String? documento,
    String? notas,
  }) async {
    cliente.nombre = nombre;
    cliente.apellido = apellido;
    cliente.telefono = telefono;
    cliente.direccion = direccion;
    cliente.email = email;
    cliente.documento = documento;
    cliente.notas = notas;

    await cliente.save();
    _registrarCambio('Cliente editado: ${cliente.nombreCompleto}');
  }

  // Eliminar cliente y su cuenta corriente
  Future<void> eliminarCliente(Cliente cliente) async {
    // Eliminar cuenta corriente asociada
    final cuenta = obtenerCuentaPorCliente(cliente);
    if (cuenta != null) {
      // Eliminar movimientos de la cuenta
      final movimientos = _movimientosBox.values
          .where((mov) => mov.cuentaId == cuenta.key.toString())
          .toList();
      
      for (final movimiento in movimientos) {
        await movimiento.delete();
      }
      
      // Eliminar la cuenta
      await cuenta.delete();
    }

    // Eliminar el cliente
    await cliente.delete();
    _registrarCambio('Cliente eliminado: ${cliente.nombreCompleto}');
  }

  // Buscar clientes
  List<Cliente> buscarClientes(String query) {
    final queryLower = query.toLowerCase();
    return _clientesBox.values.where((cliente) {
      return cliente.nombre.toLowerCase().contains(queryLower) ||
             cliente.apellido.toLowerCase().contains(queryLower) ||
             (cliente.telefono?.contains(query) ?? false) ||
             (cliente.documento?.contains(query) ?? false);
    }).toList();
  }

  // Actualizar cliente
  Future<void> actualizarCliente(Cliente cliente) async {
    await cliente.save();
    _registrarCambio('Cliente actualizado: ${cliente.nombreCompleto}');
  }

  // Desactivar cliente
  Future<void> desactivarCliente(Cliente cliente) async {
    cliente.activo = false;
    await cliente.save();
    _registrarCambio('Cliente desactivado: ${cliente.nombreCompleto}');
  }

  /// GESTIÓN DE CUENTAS CORRIENTES ///

  // Abrir cuenta corriente
  Future<CuentaCorriente> abrirCuentaCorriente({
    required Cliente cliente,
    double limiteCredito = 0.0,
    String? notas,
  }) async {
    // Verificar si ya tiene cuenta activa
    final cuentaExistente = obtenerCuentaPorCliente(cliente);
    if (cuentaExistente != null && cuentaExistente.activa) {
      throw Exception('El cliente ya tiene una cuenta corriente activa');
    }

    final cuenta = CuentaCorriente(
      clienteId: cliente.key.toString(),
      fechaApertura: DateTime.now(),
      saldoActual: 0.0,
      limiteCredito: limiteCredito,
      activa: true,
      notas: notas,
    );

    await _cuentasBox.add(cuenta);
    _registrarCambio('Cuenta corriente abierta para: ${cliente.nombreCompleto}');
    return cuenta;
  }

  // Obtener cuenta por cliente
  CuentaCorriente? obtenerCuentaPorCliente(Cliente cliente) {
    final clienteId = cliente.key.toString();
    return _cuentasBox.values
        .where((cuenta) => cuenta.clienteId == clienteId && cuenta.activa)
        .cast<CuentaCorriente?>()
        .firstWhere((cuenta) => cuenta != null, orElse: () => null);
  }

  // Obtener todas las cuentas
  List<CuentaCorriente> obtenerCuentas({bool soloActivas = true}) {
    final cuentas = _cuentasBox.values.toList();
    if (soloActivas) {
      return cuentas.where((c) => c.activa).toList();
    }
    return cuentas;
  }

  // Obtener cuentas con saldo
  List<CuentaCorriente> obtenerCuentasConSaldo() {
    return obtenerCuentas().where((cuenta) => cuenta.saldoActual > 0).toList();
  }

  // Obtener cuentas morosas
  List<CuentaCorriente> obtenerCuentasMorosas() {
    return obtenerCuentas().where((cuenta) => cuenta.saldoActual > 0 && _esCuentaMorosa(cuenta)).toList();
  }

  /// MOVIMIENTOS ///

  // Agregar cargo (compra)
  Future<MovimientoCuenta> agregarCargo({
    required CuentaCorriente cuenta,
    required double monto,
    required String descripcion,
    String? referencia,
    String? notas,
  }) async {
    final movimiento = MovimientoCuenta(
      cuentaId: cuenta.key.toString(),
      tipo: TipoMovimiento.cargo,
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion,
      referencia: referencia,
      notas: notas,
      saldoAnterior: cuenta.saldoActual,
      saldoPosterior: cuenta.saldoActual + monto,
    );

    // Actualizar saldo de la cuenta
    cuenta.saldoActual += monto;
    await cuenta.save();

    // Guardar movimiento
    await _movimientosBox.add(movimiento);
    
    final cliente = _obtenerClientePorId(cuenta.clienteId);
    _registrarCambio('Cargo agregado a ${cliente?.nombreCompleto}: \$${monto.toStringAsFixed(2)}');
    
    return movimiento;
  }

  // Registrar pago
  Future<MovimientoCuenta> registrarPago({
    required CuentaCorriente cuenta,
    required double monto,
    String? descripcion,
    String? referencia,
    String? notas,
  }) async {
    if (monto > cuenta.saldoActual) {
      throw Exception('El monto del pago (\$${monto.toStringAsFixed(2)}) no puede ser mayor al saldo actual (\$${cuenta.saldoActual.toStringAsFixed(2)})');
    }

    final movimiento = MovimientoCuenta(
      cuentaId: cuenta.key.toString(),
      tipo: TipoMovimiento.pago,
      monto: monto,
      fecha: DateTime.now(),
      descripcion: descripcion ?? 'Pago recibido',
      referencia: referencia,
      notas: notas,
      saldoAnterior: cuenta.saldoActual,
      saldoPosterior: cuenta.saldoActual - monto,
    );

    // Actualizar saldo de la cuenta
    cuenta.saldoActual -= monto;
    await cuenta.save();

    // Guardar movimiento
    await _movimientosBox.add(movimiento);
    
    final cliente = _obtenerClientePorId(cuenta.clienteId);
    _registrarCambio('Pago registrado de ${cliente?.nombreCompleto}: \$${monto.toStringAsFixed(2)}');
    
    return movimiento;
  }

  // Obtener movimientos de una cuenta
  List<MovimientoCuenta> obtenerMovimientos(CuentaCorriente cuenta, {int? limit}) {
    final cuentaId = cuenta.key.toString();
    var movimientos = _movimientosBox.values
        .where((m) => m.cuentaId == cuentaId)
        .toList();
    
    // Ordenar por fecha descendente
    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
    
    if (limit != null) {
      movimientos = movimientos.take(limit).toList();
    }
    
    return movimientos;
  }

  /// REPORTES Y ESTADÍSTICAS ///

  // Resumen general
  Map<String, dynamic> obtenerResumenGeneral() {
    final cuentas = obtenerCuentas();
    final cuentasConSaldo = cuentas.where((c) => c.saldoActual > 0);
    final cuentasMorosas = cuentasConSaldo.where((c) => _esCuentaMorosa(c));
    
    final totalClientes = obtenerClientes().length;
    final totalCuentas = cuentas.length;
    final totalDeuda = cuentasConSaldo.fold(0.0, (sum, cuenta) => sum + cuenta.saldoActual);
    final deudaMorosa = cuentasMorosas.fold(0.0, (sum, cuenta) => sum + cuenta.saldoActual);

    return {
      'totalClientes': totalClientes,
      'totalCuentas': totalCuentas,
      'cuentasConSaldo': cuentasConSaldo.length,
      'cuentasMorosas': cuentasMorosas.length,
      'totalDeuda': totalDeuda,
      'deudaMorosa': deudaMorosa,
    };
  }

  // Resumen mensual
  Map<String, dynamic> obtenerResumenMensual(DateTime mes) {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0);
    
    final movimientosMes = _movimientosBox.values.where((m) =>
        m.fecha.isAfter(inicioMes.subtract(const Duration(days: 1))) &&
        m.fecha.isBefore(finMes.add(const Duration(days: 1)))
    ).toList();

    final cargos = movimientosMes.where((m) => m.tipo == TipoMovimiento.cargo);
    final pagos = movimientosMes.where((m) => m.tipo == TipoMovimiento.pago);
    
    final totalCargos = cargos.fold(0.0, (sum, m) => sum + m.monto);
    final totalPagos = pagos.fold(0.0, (sum, m) => sum + m.monto);

    return {
      'mes': '${mes.month}/${mes.year}',
      'totalMovimientos': movimientosMes.length,
      'totalCargos': totalCargos,
      'totalPagos': totalPagos,
      'diferencia': totalCargos - totalPagos,
      'cargos': cargos.length,
      'pagos': pagos.length,
    };
  }

  /// MÉTODOS AUXILIARES ///

  Cliente? _obtenerClientePorId(String clienteId) {
    try {
      final key = int.parse(clienteId);
      return _clientesBox.get(key);
    } catch (e) {
      return null;
    }
  }

  bool _esCuentaMorosa(CuentaCorriente cuenta) {
    // Una cuenta es morosa si tiene saldo y el último cargo fue hace más de 30 días
    if (cuenta.saldoActual <= 0) return false;
    
    final movimientos = obtenerMovimientos(cuenta);
    final ultimoCargo = movimientos
        .where((m) => m.tipo == TipoMovimiento.cargo)
        .cast<MovimientoCuenta?>()
        .firstWhere((m) => m != null, orElse: () => null);
    
    if (ultimoCargo == null) return false;
    
    final diasSinPago = DateTime.now().difference(ultimoCargo.fecha).inDays;
    return diasSinPago > 30;
  }

  void _registrarCambio(String descripcion) {
    // Registrar cambio para backup
    BackupService.instance.recordChange('cuenta_corriente: $descripcion');
    debugPrint('CuentaCorriente: $descripcion');
  }

  /// DATOS COMBINADOS ///
  
  // Obtener datos completos de cliente con cuenta
  Map<String, dynamic>? obtenerDatosCompletos(Cliente cliente) {
    final cuenta = obtenerCuentaPorCliente(cliente);
    if (cuenta == null) return null;
    
    final movimientos = obtenerMovimientos(cuenta, limit: 10);
    final esMorosa = cuenta.saldoActual > 0 && _esCuentaMorosa(cuenta);
    
    return {
      'cliente': cliente,
      'cuenta': cuenta,
      'movimientos': movimientos,
      'esMorosa': esMorosa,
      'ultimoMovimiento': movimientos.isNotEmpty ? movimientos.first : null,
    };
  }
}