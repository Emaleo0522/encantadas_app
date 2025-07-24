import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 2)
enum ProductCategory {
  @HiveField(0)
  ropa,
  @HiveField(1)
  unas,
  @HiveField(2)
  bijouterie,
}

@HiveType(typeId: 3)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  ProductCategory category;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  double? cost;

  @HiveField(5)
  String? providerId;

  @HiveField(6)
  String code;

  Product({
    required this.name,
    required this.category,
    required this.quantity,
    required this.createdAt,
    required this.code,
    this.cost,
    this.providerId,
  });

  // Helper method to get category display name with emoji
  String get categoryDisplayName {
    switch (category) {
      case ProductCategory.ropa:
        return '👕 Ropa';
      case ProductCategory.unas:
        return '💅 Uñas';
      case ProductCategory.bijouterie:
        return '💍 Bijouterie';
    }
  }

  // Helper method to get category color
  Color get categoryColor {
    switch (category) {
      case ProductCategory.ropa:
        return const Color(0xFF2196F3); // Blue
      case ProductCategory.unas:
        return const Color(0xFFE91E63); // Pink
      case ProductCategory.bijouterie:
        return const Color(0xFFFF9800); // Orange
    }
  }

  // Helper method to format creation date
  String get formattedCreatedAt {
    final date = '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}';
    return date;
  }

  // Helper method to get quantity status
  String get quantityStatus {
    if (quantity == 0) {
      return 'Sin stock';
    } else if (quantity <= 5) {
      return 'Stock bajo';
    } else {
      return 'En stock';
    }
  }

  // Helper method to get quantity status color
  Color get quantityStatusColor {
    if (quantity == 0) {
      return const Color(0xFFF44336); // Red
    } else if (quantity <= 5) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return const Color(0xFF4CAF50); // Green
    }
  }

  // Helper method to format cost
  String get formattedCost {
    if (cost == null) {
      return 'Sin costo';
    }
    return '\$${cost!.toStringAsFixed(0)}';
  }

  // Helper method to check if has cost info
  bool get hasCostInfo {
    return cost != null && cost! > 0;
  }

  // Helper method to check if has provider
  bool get hasProvider {
    return providerId != null && providerId!.isNotEmpty;
  }

  // Helper method to format product code
  String get formattedCode {
    return code.toUpperCase();
  }
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.ropa:
        return '👕 Ropa';
      case ProductCategory.unas:
        return '💅 Uñas';
      case ProductCategory.bijouterie:
        return '💍 Bijouterie';
    }
  }
}