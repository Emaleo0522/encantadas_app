import 'package:hive/hive.dart';
import '../models/appointment.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../utils/product_code_generator.dart';

class SampleDataService {
  static Future<void> addSampleAppointments() async {
    final box = Hive.box<Appointment>('appointments');
    
    // Only add sample data if the box is empty
    if (box.isEmpty) {
      final sampleAppointments = [
        Appointment(
          clientName: 'María González',
          dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
          serviceName: 'Corte y peinado',
          price: 2500,
          completed: false,
        ),
        Appointment(
          clientName: 'Ana López',
          dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
          serviceName: 'Manicura y esmaltado',
          price: 1800,
          completed: true,
        ),
        Appointment(
          clientName: 'Carla Fernández',
          dateTime: DateTime.now().add(const Duration(days: 3, hours: 14)),
          serviceName: 'Tratamiento facial',
          price: 3200,
          completed: false,
        ),
        Appointment(
          clientName: 'Sofía Martín',
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
          serviceName: 'Pedicura completa',
          price: 2000,
          completed: true,
        ),
        Appointment(
          clientName: 'Elena Rodríguez',
          dateTime: DateTime.now().add(const Duration(hours: 16)),
          serviceName: 'Coloración y corte',
          price: 4500,
          completed: false,
        ),
      ];
      
      for (final appointment in sampleAppointments) {
        await box.add(appointment);
      }
    }
  }
  
  static Future<void> clearAllAppointments() async {
    final box = Hive.box<Appointment>('appointments');
    await box.clear();
  }
  
  static Future<void> clearAllTransactions() async {
    final box = Hive.box<Transaction>('transactions');
    await box.clear();
  }
  
  static Future<void> addSampleTransactions() async {
    final box = Hive.box<Transaction>('transactions');
    
    // Only add sample data if the box is empty
    if (box.isEmpty) {
      final sampleTransactions = [
        Transaction(
          amount: 1800,
          date: DateTime.now().subtract(const Duration(days: 5)),
          source: 'turno',
          clientName: 'Rosa Martínez',
          serviceName: 'Manicura francesa',
        ),
        Transaction(
          amount: 3500,
          date: DateTime.now().subtract(const Duration(days: 3)),
          source: 'turno',
          clientName: 'Laura García',
          serviceName: 'Coloración completa',
        ),
        Transaction(
          amount: 2200,
          date: DateTime.now().subtract(const Duration(days: 1)),
          source: 'turno',
          clientName: 'Carmen López',
          serviceName: 'Corte y brushing',
        ),
      ];
      
      for (final transaction in sampleTransactions) {
        await box.add(transaction);
      }
    }
  }
  
  static Future<void> addSampleProducts() async {
    final box = Hive.box<Product>('products');
    
    // Only add sample data if the box is empty
    if (box.isEmpty) {
      final sampleProducts = [
        Product(
          name: 'Esmalte rojo brillante',
          category: ProductCategory.unas,
          quantity: 15,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          code: 'P-001',
        ),
        Product(
          name: 'Anillos dorados variados',
          category: ProductCategory.bijouterie,
          quantity: 8,
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          code: 'P-002',
        ),
        Product(
          name: 'Remera básica negra',
          category: ProductCategory.ropa,
          quantity: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          code: 'P-003',
        ),
        Product(
          name: 'Collar de perlas',
          category: ProductCategory.bijouterie,
          quantity: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          code: 'P-004',
        ),
        Product(
          name: 'Base coat transparente',
          category: ProductCategory.unas,
          quantity: 20,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          code: 'P-005',
        ),
        Product(
          name: 'Jean azul clásico',
          category: ProductCategory.ropa,
          quantity: 7,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          code: 'P-006',
        ),
        Product(
          name: 'Aros plateados',
          category: ProductCategory.bijouterie,
          quantity: 12,
          createdAt: DateTime.now(),
          code: 'P-007',
        ),
      ];
      
      for (final product in sampleProducts) {
        await box.add(product);
      }
    }
  }
  
  static Future<void> clearAllProducts() async {
    final box = Hive.box<Product>('products');
    await box.clear();
  }
}