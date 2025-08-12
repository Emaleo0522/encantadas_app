import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/provider.dart';
import '../widgets/qr_code_dialog.dart';
import 'providers_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProvidersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.business),
            tooltip: 'Proveedores',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Product>>(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, box, _) {
          final products = box.values.toList().cast<Product>();
          
          // Sort products by category and then by name
          products.sort((a, b) {
            final categoryComparison = a.category.index.compareTo(b.category.index);
            if (categoryComparison != 0) return categoryComparison;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin productos por el momento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para agregar tu primer producto',
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
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProductCard(product: product),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QRCodeDialog(
          productCode: product.code,
          productName: product.name,
        );
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Eliminar este producto?'),
          content: Text(
            'Se eliminará "${product.name}" permanentemente del stock. Esta acción no se puede deshacer.',
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
        await product.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Producto eliminado del stock'),
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
              content: Text('Error al eliminar producto: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _editQuantity(BuildContext context) async {
    final controller = TextEditingController(text: product.quantity.toString());
    
    final newQuantity = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar cantidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Producto: ${product.name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Cantidad actual: ${product.quantity} unidades',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nueva cantidad',
                  suffixText: 'unidades',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  final quantity = int.tryParse(value);
                  if (quantity != null && quantity >= 0) {
                    Navigator.of(context).pop(quantity);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final quantity = int.tryParse(controller.text);
                if (quantity != null && quantity >= 0) {
                  Navigator.of(context).pop(quantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese una cantidad válida (0 o mayor)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newQuantity != null && context.mounted) {
      await _updateQuantity(context, newQuantity);
    }
    
    controller.dispose();
  }

  Future<void> _updateQuantity(BuildContext context, int newQuantity) async {
    try {
      final oldQuantity = product.quantity;
      product.quantity = newQuantity;
      await product.save();

      if (context.mounted) {
        final difference = newQuantity - oldQuantity;
        final message = difference > 0 
            ? 'Stock aumentado en ${difference.abs()} unidades'
            : difference < 0 
                ? 'Stock reducido en ${difference.abs()} unidades'
                : 'Cantidad actualizada';
                
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  difference > 0 ? Icons.add : difference < 0 ? Icons.remove : Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar cantidad: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _quickAdjustQuantity(BuildContext context, int adjustment) async {
    final newQuantity = (product.quantity + adjustment).clamp(0, 99999);
    if (newQuantity != product.quantity) {
      await _updateQuantity(context, newQuantity);
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
            // Product name and status row with menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
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
                    color: theme.iconTheme.color?.withOpacity(0.7),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProduct(context);
                    } else if (value == 'edit') {
                      _editQuantity(context);
                    } else if (value == 'qr') {
                      _showQRCode(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: Colors.purple, size: 18),
                          SizedBox(width: 8),
                          Text('Ver código QR'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Editar cantidad'),
                        ],
                      ),
                    ),
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.quantityStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: product.quantityStatusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    product.quantityStatus,
                    style: TextStyle(
                      color: product.quantityStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Category
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: product.categoryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  product.categoryDisplayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: product.categoryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Product code
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  size: 16,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Código: ${product.formattedCode}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.iconTheme.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showQRCode(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code,
                          color: Colors.purple,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Ver QR',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Quantity with +/- controls
            Row(
              children: [
                Icon(
                  Icons.numbers,
                  size: 16,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  '${product.quantity} unidades',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: product.quantityStatusColor,
                  ),
                ),
                const Spacer(),
                // Quick adjustment controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: product.quantity > 0 
                          ? () => _quickAdjustQuantity(context, -1)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.quantity > 0 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          border: Border.all(
                            color: product.quantity > 0 
                                ? Colors.red.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: product.quantity > 0 
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _quickAdjustQuantity(context, 1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Cost and pricing info
            if (product.hasCostInfo || product.hasSalePriceInfo || product.hasProvider) ...[
              if (product.hasCostInfo)
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Costo: ${product.formattedCost}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              if (product.hasCostInfo && product.hasSalePriceInfo)
                const SizedBox(height: 6),
              if (product.hasSalePriceInfo)
                Row(
                  children: [
                    Icon(
                      Icons.sell,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Venta: ${product.formattedCalculatedSalePrice}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (product.usePercentage && product.profitPercentage != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${product.profitPercentage!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (product.hasSalePriceInfo && product.hasCostInfo)
                ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ganancia: ${product.formattedProfit}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if ((product.hasCostInfo || product.hasSalePriceInfo) && product.hasProvider)
                const SizedBox(height: 6),
              if (product.hasProvider)
                ValueListenableBuilder<Box<Provider>>(
                  valueListenable: Hive.box<Provider>('providers').listenable(),
                  builder: (context, box, _) {
                    Provider? provider;
                    if (product.providerId != null) {
                      // Buscar el proveedor por su key
                      for (var p in box.values) {
                        if (p.key.toString() == product.providerId) {
                          provider = p;
                          break;
                        }
                      }
                    }
                    
                    if (provider == null) {
                      return const SizedBox.shrink();
                    }
                    
                    return Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Proveedor: ${provider.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
            
            // Created date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Agregado: ${product.formattedCreatedAt}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}