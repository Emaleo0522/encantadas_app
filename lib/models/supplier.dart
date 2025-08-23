import 'package:hive/hive.dart';

part 'supplier.g.dart';

@HiveType(typeId: 5)
class Supplier extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? contactNumber;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  DateTime createdAt;

  Supplier({
    required this.name,
    this.contactNumber,
    required this.category,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper method to format contact number
  String get formattedContactNumber {
    if (contactNumber == null || contactNumber!.isEmpty) {
      return 'Sin número';
    }
    return contactNumber!;
  }

  // Helper method to get category display name
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'ropa':
        return '👗 Ropa';
      case 'bijouterie':
        return '💎 Bijouterie';
      case 'pedicura':
        return '💅 Pedicura';
      case 'manicura':
        return '💅 Manicura';
      case 'belleza':
        return '✨ Belleza';
      case 'accesorios':
        return '👜 Accesorios';
      case 'calzado':
        return '👠 Calzado';
      case 'cosmeticos':
        return '💄 Cosméticos';
      case 'herramientas':
        return '🔧 Herramientas';
      case 'otros':
        return '📦 Otros';
      default:
        return '📦 ${category}';
    }
  }

  // Helper method to format creation date
  String get formattedCreatedAt {
    final date = '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}';
    return date;
  }

  // Helper method to get notes preview
  String get notesPreview {
    if (notes == null || notes!.isEmpty) {
      return 'Sin notas';
    }
    if (notes!.length <= 50) {
      return notes!;
    }
    return '${notes!.substring(0, 50)}...';
  }

  // Static method to get available categories
  static List<String> getAvailableCategories() {
    return [
      'Ropa',
      'Bijouterie',
      'Pedicura',
      'Manicura',
      'Belleza',
      'Accesorios',
      'Calzado',
      'Cosméticos',
      'Herramientas',
      'Otros',
    ];
  }

  // Static method to validate phone number format
  static bool isValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return true; // Optional field
    }
    
    // Remove spaces, hyphens, and parentheses
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it contains only digits and optional + at the beginning
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  // Method to get clean phone number (digits only)
  String? get cleanContactNumber {
    if (contactNumber == null || contactNumber!.isEmpty) {
      return null;
    }
    return contactNumber!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Convert supplier to JSON for backup
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'contactNumber': contactNumber,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create supplier from JSON for restore
  static Supplier fromJson(Map<String, dynamic> json) {
    return Supplier(
      name: json['name'] as String,
      category: json['category'] as String,
      contactNumber: json['contactNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}