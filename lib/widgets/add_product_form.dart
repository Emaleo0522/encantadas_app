import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/provider.dart';
import '../utils/product_code_generator.dart';

class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  
  ProductCategory _selectedCategory = ProductCategory.ropa;
  Provider? _selectedProvider;
  bool _isLoading = false;
  String _previewCode = '';

  @override
  void initState() {
    super.initState();
    _updatePreviewCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _updatePreviewCode() {
    setState(() {
      _previewCode = ProductCodeGenerator.getNextCode();
    });
  }

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.ropa:
        return const Color(0xFF2196F3); // Blue
      case ProductCategory.unas:
        return const Color(0xFFE91E63); // Pink
      case ProductCategory.bijouterie:
        return const Color(0xFFFF9800); // Orange
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final box = Hive.box<Product>('products');
      final uniqueCode = ProductCodeGenerator.generateUniqueCode();
      
      final product = Product(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        quantity: int.parse(_quantityController.text.trim()),
        createdAt: DateTime.now(),
        code: uniqueCode,
        cost: _costController.text.trim().isEmpty 
            ? null 
            : double.parse(_costController.text.trim()),
        providerId: _selectedProvider?.key?.toString(),
      );

      await box.add(product);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Producto "${product.name}" agregado al stock',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Nuevo Producto',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Product name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                prefixIcon: Icon(Icons.inventory_2),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre del producto es obligatorio';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<ProductCategory>(
              value: _selectedCategory,
              onChanged: (ProductCategory? value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem<ProductCategory>(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantity field
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad inicial',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
                suffixText: 'unidades',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La cantidad es obligatoria';
                }
                final quantity = int.tryParse(value.trim());
                if (quantity == null || quantity < 0) {
                  return 'Ingrese una cantidad válida (0 o mayor)';
                }
                if (quantity > 99999) {
                  return 'La cantidad no puede exceder 99,999';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cost field (optional)
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Precio de costo (opcional)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final cost = double.tryParse(value.trim());
                  if (cost == null || cost < 0) {
                    return 'Ingrese un costo válido';
                  }
                  if (cost > 999999) {
                    return 'El costo no puede exceder \$999,999';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Provider dropdown (optional)
            ValueListenableBuilder<Box<Provider>>(
              valueListenable: Hive.box<Provider>('providers').listenable(),
              builder: (context, box, _) {
                final providers = box.values.toList().cast<Provider>();
                providers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                return DropdownButtonFormField<Provider>(
                  value: _selectedProvider,
                  onChanged: (Provider? value) {
                    setState(() {
                      _selectedProvider = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Proveedor (opcional)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar proveedor'),
                  items: [
                    const DropdownMenuItem<Provider>(
                      value: null,
                      child: Text('Sin proveedor'),
                    ),
                    ...providers.map((provider) {
                      return DropdownMenuItem<Provider>(
                        value: provider,
                        child: Text(
                          provider.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Category preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: _getCategoryColor(_selectedCategory),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Categoría: ${_selectedCategory.displayName}',
                    style: TextStyle(
                      color: _getCategoryColor(_selectedCategory),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Code preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code,
                    color: Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Código: $_previewCode',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '(Auto)',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar producto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}