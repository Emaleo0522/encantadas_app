import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/cuenta_corriente.dart';
import '../models/movimiento_cuenta.dart';
import '../services/cuenta_corriente_service.dart';
import 'agregar_cargo_dialog.dart';
import 'registrar_pago_dialog.dart';

class CuentaDetalleDialog extends StatefulWidget {
  final Cliente cliente;

  const CuentaDetalleDialog({
    super.key,
    required this.cliente,
  });

  @override
  State<CuentaDetalleDialog> createState() => _CuentaDetalleDialogState();
}

class _CuentaDetalleDialogState extends State<CuentaDetalleDialog> {
  final CuentaCorrienteService _service = CuentaCorrienteService.instance;
  late CuentaCorriente? cuenta;
  List<MovimientoCuenta> movimientos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    cuenta = _service.obtenerCuentaPorCliente(widget.cliente);
    if (cuenta != null) {
      movimientos = _service.obtenerMovimientos(cuenta!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (cuenta != null) ...[
              _buildResumenCuenta(),
              _buildAcciones(),
              const Divider(),
              _buildMovimientos(),
            ] else ...[
              _buildSinCuenta(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cliente.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.cliente.telefono != null)
                  Text(
                    widget.cliente.telefono!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCuenta() {
    final saldo = cuenta!.saldoActual;
    final esMorosa = cuenta!.esMorosa;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildTarjetaInfo(
              'Saldo Actual',
              '\$${saldo.toStringAsFixed(2)}',
              saldo > 0 ? Colors.red : Colors.green,
              saldo > 0 ? Icons.trending_up : Icons.check_circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTarjetaInfo(
              'Estado',
              esMorosa ? 'MOROSO' : saldo > 0 ? 'CON SALDO' : 'AL DÍA',
              esMorosa ? Colors.red : saldo > 0 ? Colors.orange : Colors.green,
              esMorosa ? Icons.warning : saldo > 0 ? Icons.schedule : Icons.check,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaInfo(String titulo, String valor, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _agregarCargo,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Agregar Cargo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: cuenta!.saldoActual > 0 ? _registrarPago : null,
              icon: const Icon(Icons.payment),
              label: const Text('Registrar Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientos() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Últimos Movimientos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: movimientos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay movimientos registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: movimientos.length,
                    itemBuilder: (context, index) {
                      final movimiento = movimientos[index];
                      return _buildMovimientoItem(movimiento);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientoItem(MovimientoCuenta movimiento) {
    final esCargo = movimiento.tipo == TipoMovimiento.cargo;
    final color = esCargo ? Colors.red : Colors.green;
    final icono = esCargo ? Icons.add_shopping_cart : Icons.payment;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color, size: 20),
        ),
        title: Text(
          movimiento.descripcion,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${movimiento.fecha.day}/${movimiento.fecha.month}/${movimiento.fecha.year}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${esCargo ? '+' : '-'}\$${movimiento.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              'Saldo: \$${movimiento.saldoPosterior.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinCuenta() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sin cuenta corriente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este cliente no tiene una cuenta corriente activa',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _crearCuentaCorriente,
              icon: const Icon(Icons.add_card),
              label: const Text('Crear Cuenta Corriente'),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarCargo() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AgregarCargoDialog(cuenta: cuenta!),
    );
    
    if (resultado == true) {
      _cargarDatos();
    }
  }

  void _registrarPago() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => RegistrarPagoDialog(cuenta: cuenta!),
    );
    
    if (resultado == true) {
      _cargarDatos();
    }
  }

  void _crearCuentaCorriente() async {
    try {
      await _service.abrirCuentaCorriente(
        cliente: widget.cliente,
        notas: 'Cuenta creada desde detalle de cliente',
      );
      
      _cargarDatos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta corriente creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}