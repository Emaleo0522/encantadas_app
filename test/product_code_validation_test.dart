import 'package:flutter_test/flutter_test.dart';
import 'package:encantadas_app/utils/validate_product_code.dart';
import 'package:encantadas_app/utils/product_code_generator.dart';

void main() {
  group('ProductCodeValidator Basic Tests', () {
    group('isCodeValid', () {
      test('should return true for valid codes', () {
        expect(ProductCodeValidator.isCodeValid('P-001'), isTrue);
        expect(ProductCodeValidator.isCodeValid('ABC123'), isTrue);
        expect(ProductCodeValidator.isCodeValid('PROD-001'), isTrue);
        expect(ProductCodeValidator.isCodeValid('TEST123'), isTrue);
      });

      test('should return false for invalid codes', () {
        expect(ProductCodeValidator.isCodeValid(''), isFalse);
        expect(ProductCodeValidator.isCodeValid('AB'), isFalse); // Too short
        expect(ProductCodeValidator.isCodeValid('A' * 51), isFalse); // Too long
        expect(ProductCodeValidator.isCodeValid('TEST\n001'), isFalse); // Contains newline
        expect(ProductCodeValidator.isCodeValid('TEST\t001'), isFalse); // Contains tab
        expect(ProductCodeValidator.isCodeValid('TEST\r001'), isFalse); // Contains carriage return
      });
    });

    group('validateScannedCode - format validation', () {
      test('should return invalid result for invalid format', () {
        final result = ProductCodeValidator.validateScannedCode('');
        expect(result.isValid, isFalse);
        expect(result.errorType, equals(ScanErrorType.invalidFormat));
        expect(result.message, contains('inválido'));
      });

      test('should return invalid result for codes with special characters', () {
        final result = ProductCodeValidator.validateScannedCode('TEST\n001');
        expect(result.isValid, isFalse);
        expect(result.errorType, equals(ScanErrorType.invalidFormat));
      });

      test('should return invalid result for non-existent product', () {
        // This will fail because no Hive data, but tests the flow
        final result = ProductCodeValidator.validateScannedCode('P-NOTFOUND');
        expect(result.isValid, isFalse);
        expect(result.errorType, equals(ScanErrorType.productNotFound));
        expect(result.message, contains('no encontrado'));
      });
    });

    group('generateUniqueCode', () {
      test('should generate valid codes', () {
        final code1 = ProductCodeValidator.generateUniqueCode();
        final code2 = ProductCodeValidator.generateUniqueCode();
        
        expect(code1, isNotEmpty);
        expect(code2, isNotEmpty);
        expect(code1, isNot(equals(code2)));
        expect(ProductCodeValidator.isCodeValid(code1), isTrue);
        expect(ProductCodeValidator.isCodeValid(code2), isTrue);
      });

      test('should generate codes with custom prefix', () {
        final code = ProductCodeValidator.generateUniqueCode(prefix: 'TEST-');
        expect(code, startsWith('TEST-'));
        expect(ProductCodeValidator.isCodeValid(code), isTrue);
      });

      test('should generate codes with different prefixes', () {
        final code1 = ProductCodeValidator.generateUniqueCode(prefix: 'A-');
        final code2 = ProductCodeValidator.generateUniqueCode(prefix: 'B-');
        
        expect(code1, startsWith('A-'));
        expect(code2, startsWith('B-'));
        expect(code1, isNot(equals(code2)));
      });
    });
  });

  group('ProductCodeGenerator Tests', () {
    test('should generate valid codes', () {
      final code = ProductCodeGenerator.generateUniqueCode();
      expect(code, isNotEmpty);
      expect(ProductCodeGenerator.isValidCode(code), isTrue);
      expect(code, startsWith('P-')); // Should use default prefix
    });

    test('should validate codes correctly', () {
      expect(ProductCodeGenerator.isValidCode('P-001'), isTrue);
      expect(ProductCodeGenerator.isValidCode('P-ABC'), isTrue);
      expect(ProductCodeGenerator.isValidCode('P-123'), isTrue);
      expect(ProductCodeGenerator.isValidCode(''), isFalse);
      expect(ProductCodeGenerator.isValidCode('XY'), isFalse);
      expect(ProductCodeGenerator.isValidCode('TOOLONG12345678901234567890'), isFalse);
    });

    test('should generate sequential-style codes', () {
      final codes = <String>[];
      for (int i = 0; i < 5; i++) {
        codes.add(ProductCodeGenerator.generateUniqueCode());
      }
      
      // All codes should be unique
      final uniqueCodes = codes.toSet();
      expect(uniqueCodes.length, equals(codes.length));
      
      // All should be valid
      for (final code in codes) {
        expect(ProductCodeGenerator.isValidCode(code), isTrue);
      }
    });
  });
}