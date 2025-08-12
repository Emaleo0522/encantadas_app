import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/product.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSales = <String>{};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSales.clear();
      }
    });
  }

  void _toggleSaleSelection(String saleKey) {
    setState(() {
      if (_selectedSales.contains(saleKey)) {
        _selectedSales.remove(saleKey);
      } else {
        _selectedSales.add(saleKey);
      }
    });
  }

  void _selectAllSales(List<Transaction> sales) {
    setState(() {
      if (_selectedSales.length == sales.length) {
        _selectedSales.clear();
      } else {
        _selectedSales.clear();
        for (final sale in sales) {
          _selectedSales.add(sale.key.toString());
        }
      }
    });
  }

  /// Muestra diálogo de confirmación para eliminar múltiples ventas
  Future<void> _showMultipleDeleteConfirmation(BuildContext context, List<Transaction> selectedSales) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text('Eliminar ${selectedSales.length} ventas'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Estás seguro? Esta acción restaurará el stock y ajustará el balance.'),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: selectedSales.map((sale) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.isProductSale ? sale.productName! : sale.serviceName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    sale.formattedAmount,
                                    style: const TextStyle(color: Colors.green, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar todas'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await _deleteMultipleSales(context, selectedSales);
    }
  }

  /// Elimina múltiples ventas y restaura el stock
  Future<void> _deleteMultipleSales(BuildContext context, List<Transaction> salesToDelete) async {
    int successCount = 0;
    int errorCount = 0;
    List<String> productErrors = [];

    try {
      final productsBox = Hive.box<Product>('products');

      for (final sale in salesToDelete) {
        try {
          // Si es una venta de producto, restaurar stock
          if (sale.isProductSale && sale.productName != null && sale.quantity != null) {
            // Buscar producto por nombre
            Product? product;
            for (final p in productsBox.values) {
              if (p.name == sale.productName) {
                product = p;
                break;
              }
            }

            if (product != null) {
              // Restaurar stock
              product.quantity += sale.quantity!;
              await product.save();
            } else {
              // Producto no encontrado
              productErrors.add(sale.productName!);
            }
          }

          // Eliminar la transacción
          await sale.delete();
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Salir del modo selección
      setState(() {
        _isSelectionMode = false;
        _selectedSales.clear();
      });

      // Mostrar mensajes de resultado
      if (context.mounted) {
        if (productErrors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Algunos productos fueron eliminados, no se pudo restaurar stock: ${productErrors.join(", ")}'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Se eliminaron $successCount ventas correctamente.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Ocurrieron $errorCount errores durante la eliminación.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error al eliminar ventas: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Muestra diálogo de confirmación para eliminar venta
  Future<void> _showDeleteConfirmation(BuildContext context, Transaction sale) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Confirmar eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de eliminar esta venta?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.isProductSale ? sale.productName! : sale.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (sale.isProductSale && sale.quantity != null) ...[
                      const SizedBox(height: 4),
                      Text('Cantidad: ${sale.formattedQuantity}'),
                    ],
                    const SizedBox(height: 4),
                    Text('Total: ${sale.formattedAmount}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta acción restaurará el stock del producto y ajustará el balance.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await _deleteSale(context, sale);
    }
  }

  /// Elimina la venta y restaura el stock
  Future<void> _deleteSale(BuildContext context, Transaction sale) async {
    try {
      // Si es una venta de producto, restaurar stock
      if (sale.isProductSale && sale.productName != null && sale.quantity != null) {
        final productsBox = Hive.box<Product>('products');
        
        // Buscar producto por nombre
        Product? product;
        for (final p in productsBox.values) {
          if (p.name == sale.productName) {
            product = p;
            break;
          }
        }

        if (product != null) {
          // Restaurar stock
          product.quantity += sale.quantity!;
          await product.save();
        } else {
          // Producto no encontrado, mostrar advertencia pero continuar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('No se puede restaurar stock, el producto ha sido eliminado'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Eliminar la transacción
      await sale.delete();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Venta eliminada correctamente. Stock y balance restaurados.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error al eliminar venta: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedSales.length} seleccionadas')
            : const Text('Ventas'),
        leading: _isSelectionMode 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist_rtl),
              onPressed: _toggleSelectionMode,
              tooltip: 'Selección múltiple',
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                final box = Hive.box<Transaction>('transactions');
                final salesTransactions = box.values
                    .where((transaction) => transaction.source.toLowerCase() == 'venta')
                    .toList();
                _selectAllSales(salesTransactions);
              },
              tooltip: 'Seleccionar todo',
            ),
        ],
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: Hive.box<Transaction>('transactions').listenable(),
        builder: (context, box, _) {
          // Filter only sales transactions
          final allTransactions = box.values.toList().cast<Transaction>();
          final salesTransactions = allTransactions
              .where((transaction) => transaction.source.toLowerCase() == 'venta')
              .toList();
          
          // Sort by date (newest first)
          salesTransactions.sort((a, b) => b.date.compareTo(a.date));

          if (salesTransactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay ventas registradas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para registrar tu primera venta',
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
            itemCount: salesTransactions.length,
            itemBuilder: (context, index) {
              final sale = salesTransactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SaleCard(
                  transaction: sale,
                  onDelete: _isSelectionMode ? null : () => _showDeleteConfirmation(context, sale),
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedSales.contains(sale.key.toString()),
                  onSelectionChanged: (selected) => _toggleSaleSelection(sale.key.toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode && _selectedSales.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final box = Hive.box<Transaction>('transactions');
                final allTransactions = box.values.toList().cast<Transaction>();
                final salesTransactions = allTransactions
                    .where((transaction) => transaction.source.toLowerCase() == 'venta')
                    .toList();
                final selectedSales = salesTransactions
                    .where((sale) => _selectedSales.contains(sale.key.toString()))
                    .toList();
                _showMultipleDeleteConfirmation(context, selectedSales);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.delete_sweep),
              label: Text('Eliminar ${_selectedSales.length}'),
            )
          : null,
    );
  }
}

class SaleCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  const SaleCard({
    super.key,
    required this.transaction,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: InkWell(
        onTap: isSelectionMode ? () => onSelectionChanged?.call(!isSelected) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product name and total row
            Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelectionChanged,
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    transaction.isProductSale 
                        ? transaction.productName! 
                        : transaction.serviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    transaction.formattedAmount,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDelete != null && !isSelectionMode) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Eliminar venta',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Quantity and unit price (for product sales)
            if (transaction.isProductSale && transaction.quantity != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.shopping_basket,
                    size: 16,
                    color: theme.iconTheme.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cantidad: ${transaction.formattedQuantity}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  if (transaction.unitPrice != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      '• ${transaction.formattedUnitPrice} c/u',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fecha: ${transaction.formattedDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    transaction.formattedSource,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}