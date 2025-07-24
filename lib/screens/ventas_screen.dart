import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
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
                child: SaleCard(transaction: sale),
              );
            },
          );
        },
      ),
    );
  }
}

class SaleCard extends StatelessWidget {
  final Transaction transaction;

  const SaleCard({
    super.key,
    required this.transaction,
  });

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
            // Product name and total row
            Row(
              children: [
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
                    color: Colors.green.withValues(alpha: 0.1),
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
                    color: theme.iconTheme.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cantidad: ${transaction.formattedQuantity}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  if (transaction.unitPrice != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      '• ${transaction.formattedUnitPrice} c/u',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                  color: theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fecha: ${transaction.formattedDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
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
    );
  }
}