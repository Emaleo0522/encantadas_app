import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/provider.dart';
import '../widgets/add_provider_form.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
      ),
      body: ValueListenableBuilder<Box<Provider>>(
        valueListenable: Hive.box<Provider>('providers').listenable(),
        builder: (context, box, _) {
          final providers = box.values.toList().cast<Provider>();
          
          // Sort providers by name
          providers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (providers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin proveedores por el momento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para agregar tu primer proveedor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProviderCard(provider: provider),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddProviderForm(),
          );
        },
        tooltip: 'Agregar nuevo proveedor',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  final Provider provider;

  const ProviderCard({
    super.key,
    required this.provider,
  });

  Future<void> _deleteProvider(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Eliminar este proveedor?'),
          content: Text(
            'Se eliminará "${provider.name}" permanentemente. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await provider.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Proveedor eliminado'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar proveedor: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider name row with menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Three-dot menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.iconTheme.color?.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProvider(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (provider.contact != null && provider.contact!.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Contact info
              Row(
                children: [
                  Icon(
                    Icons.contact_phone,
                    size: 16,
                    color: theme.iconTheme.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.formattedContact,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}