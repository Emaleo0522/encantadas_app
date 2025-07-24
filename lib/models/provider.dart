import 'package:hive/hive.dart';

part 'provider.g.dart';

@HiveType(typeId: 4)
class Provider extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? contact;

  Provider({
    required this.name,
    this.contact,
  });

  // Helper method to get formatted contact info
  String get formattedContact {
    if (contact == null || contact!.isEmpty) {
      return 'Sin contacto';
    }
    
    // Check if it looks like a phone number
    final cleanContact = contact!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanContact.length >= 8) {
      return '📱 $contact';
    }
    
    return '📞 $contact';
  }

  // Helper method to get display info
  String get displayInfo {
    if (contact == null || contact!.isEmpty) {
      return name;
    }
    return '$name • ${formattedContact}';
  }

  // Helper method to check if contact is WhatsApp-like
  bool get hasWhatsApp {
    if (contact == null) return false;
    final lower = contact!.toLowerCase();
    return lower.contains('whatsapp') || 
           lower.contains('wsp') || 
           lower.contains('wa');
  }

  @override
  String toString() => name;
}