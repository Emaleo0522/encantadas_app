import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 0)
class Appointment extends HiveObject {
  @HiveField(0)
  String clientName;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  String serviceName;

  @HiveField(3)
  double price;

  @HiveField(4)
  bool completed;

  Appointment({
    required this.clientName,
    required this.dateTime,
    required this.serviceName,
    required this.price,
    this.completed = false,
  });

  // Helper method to format date and time
  String get formattedDateTime {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date - $time';
  }

  // Helper method to get status text
  String get statusText {
    return completed ? 'Concretado' : 'Pendiente';
  }

  // Helper method to format price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(0)}';
  }
}