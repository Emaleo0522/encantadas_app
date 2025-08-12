import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cliente.dart';
import '../models/cuenta_corriente.dart';
import '../services/cuenta_corriente_service.dart';
import '../screens/cuenta_corriente_screen.dart';

class AlertaCuentasMorosas extends StatefulWidget {
  const AlertaCuentasMorosas({super.key});

  @override
  State<AlertaCuentasMorosas> createState() => _AlertaCuentasMorosasState();
}

class _AlertaCuentasMorosasState extends State<AlertaCuentasMorosas> {
  final CuentaCorrienteService _service = CuentaCorrienteService.instance;
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    final cuentasMorosas = _service.obtenerCuentasMorosas();
    
    if (cuentasMorosas.isEmpty || !_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Clientes con deudas vencidas!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isVisible = false;
                  });
                },
                icon: Icon(Icons.close, color: Colors.red[700], size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tienes ${cuentasMorosas.length} cliente${cuentasMorosas.length > 1 ? 's' : ''} con deudas de más de 30 días.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          
          // Mostrar hasta 3 clientes morosos
          ...cuentasMorosas.take(3).map((cuenta) {
            final cliente = _obtenerClientePorId(cuenta.clienteId);
            if (cliente == null) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.red.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.red, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Debe: \$${cuenta.saldoActual.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cliente.telefono != null)
                    IconButton(
                      onPressed: () => _llamarCliente(cliente.telefono!),
                      icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                      tooltip: 'Llamar',
                    ),
                ],
              ),
            );
          }),
          
          if (cuentasMorosas.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              'Y ${cuentasMorosas.length - 3} cliente${cuentasMorosas.length - 3 > 1 ? 's' : ''} más...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verTodos(),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver todos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _recordarPagos(),
                  icon: const Icon(Icons.notifications, size: 18),
                  label: const Text('Recordar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Cliente? _obtenerClientePorId(String clienteId) {
    try {
      final key = int.parse(clienteId);
      return Hive.box<Cliente>('clientes_cuenta').get(key);
    } catch (e) {
      return null;
    }
  }

  void _llamarCliente(String telefono) {
    // TODO: Implementar llamada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Llamar a $telefono'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _verTodos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CuentaCorrienteScreen(),
      ),
    );
  }

  void _recordarPagos() {
    // TODO: Implementar sistema de recordatorios/notificaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Función de recordatorios - Próximamente'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}