import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class ProductCodeGenerator {
  static const String _codePrefix = 'P-';
  static const int _codeLength = 6; // Total length including prefix (P-001)
  static final Random _random = Random();

  /// Generates a unique product code
  /// Format: P-001, P-002, etc. (incremental)
  /// If incremental fails, falls back to random alphanumeric
  static String generateUniqueCode() {
    final box = Hive.box<Product>('products');
    
    // Try incremental approach first
    String code = _generateIncrementalCode(box);
    
    // If incremental code already exists, try random approach
    int attempts = 0;
    while (_codeExists(box, code) && attempts < 100) {
      code = _generateRandomCode();
      attempts++;
    }
    
    // If still not unique after 100 attempts, use timestamp-based
    if (_codeExists(box, code)) {
      code = _generateTimestampCode();
    }
    
    return code;
  }

  /// Generates incremental code based on existing products
  static String _generateIncrementalCode(Box<Product> box) {
    final products = box.values.toList();
    
    if (products.isEmpty) {
      return '${_codePrefix}001';
    }
    
    // Find the highest number in existing codes
    int maxNumber = 0;
    for (final product in products) {
      if (product.code.startsWith(_codePrefix)) {
        final numberPart = product.code.substring(_codePrefix.length);
        final number = int.tryParse(numberPart) ?? 0;
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    // Generate next incremental code
    final nextNumber = maxNumber + 1;
    return '$_codePrefix${nextNumber.toString().padLeft(3, '0')}';
  }

  /// Generates random alphanumeric code
  static String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final codeLength = _codeLength - _codePrefix.length;
    
    String code = _codePrefix;
    for (int i = 0; i < codeLength; i++) {
      code += chars[_random.nextInt(chars.length)];
    }
    
    return code;
  }

  /// Generates timestamp-based code (fallback)
  static String _generateTimestampCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shortTimestamp = timestamp.toString().substring(timestamp.toString().length - 5);
    return '$_codePrefix$shortTimestamp';
  }

  /// Checks if a code already exists in the database
  static bool _codeExists(Box<Product> box, String code) {
    return box.values.any((product) => product.code.toLowerCase() == code.toLowerCase());
  }

  /// Validates if a code follows the expected format
  static bool isValidCode(String code) {
    if (code.isEmpty) return false;
    
    // Must start with prefix
    if (!code.toUpperCase().startsWith(_codePrefix.toUpperCase())) {
      return false;
    }
    
    // Must have correct length
    if (code.length != _codeLength) {
      return false;
    }
    
    // Suffix must be alphanumeric
    final suffix = code.substring(_codePrefix.length);
    final alphanumericRegex = RegExp(r'^[A-Z0-9]+$');
    
    return alphanumericRegex.hasMatch(suffix.toUpperCase());
  }

  /// Gets the next available incremental code (for display purposes)
  static String getNextCode() {
    final box = Hive.box<Product>('products');
    return _generateIncrementalCode(box);
  }
}