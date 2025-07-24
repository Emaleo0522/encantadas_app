import 'package:flutter/material.dart';
import '../services/sample_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pantalla de Inicio en construcción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Funciones de prueba:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await SampleDataService.addSampleAppointments();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Datos de prueba agregados en Turnos'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Agregar turnos de prueba'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await SampleDataService.clearAllAppointments();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos los turnos han sido eliminados'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar todos los turnos'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await SampleDataService.addSampleProducts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Productos de prueba agregados en Stock'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text('Agregar productos de prueba'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await SampleDataService.clearAllProducts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos los productos han sido eliminados'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar todos los productos'),
            ),
          ],
        ),
      ),
    );
  }
}