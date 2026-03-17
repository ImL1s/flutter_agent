import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

// RED: file doesn't exist yet
// ignore: uri_does_not_exist

void main() {
  late SensitiveDataMasker masker;

  setUp(() {
    masker = SensitiveDataMasker();
  });

  group('email masking', () {
    test('masks email addresses in labels', () {
      final node = const WidgetDescriptor(
        id: '1', label: 'Email: john@example.com', role: 'textField',
      );
      final masked = masker.mask(node);
      expect(masked.label, isNot(contains('john@example.com')));
      expect(masked.label, contains('•'));
    });

    test('masks email in value field', () {
      final node = const WidgetDescriptor(
        id: '1', label: 'Email', role: 'textField',
        value: 'user@test.org',
      );
      final masked = masker.mask(node);
      expect(masked.value, isNot(contains('user@test.org')));
    });
  });

  group('phone masking', () {
    test('masks phone numbers in values', () {
      final node = const WidgetDescriptor(
        id: '1', label: 'Phone', role: 'textField',
        value: '+1-555-123-4567',
      );
      final masked = masker.mask(node);
      expect(masked.value, isNot(contains('555-123-4567')));
      expect(masked.value, contains('•'));
    });
  });

  group('credit card masking', () {
    test('masks credit card numbers', () {
      final node = const WidgetDescriptor(
        id: '1', label: 'Card', role: 'textField',
        value: '4111-1111-1111-1111',
      );
      final masked = masker.mask(node);
      expect(masked.value, isNot(contains('4111-1111-1111-1111')));
    });
  });

  group('non-sensitive content', () {
    test('preserves non-sensitive content', () {
      final node = const WidgetDescriptor(
        id: '1', label: 'Submit', role: 'button',
        actions: ['tap'],
      );
      final masked = masker.mask(node);
      expect(masked.label, 'Submit');
      expect(masked.role, 'button');
      expect(masked.id, '1');
      expect(masked.actions, ['tap']);
    });
  });

  group('recursive masking', () {
    test('masks recursively in children', () {
      final tree = const WidgetDescriptor(
        id: '1', label: 'Form', role: 'generic',
        children: [
          WidgetDescriptor(
            id: '2', label: 'Email', role: 'textField',
            value: 'secret@mail.com',
          ),
          WidgetDescriptor(
            id: '3', label: 'Name', role: 'textField',
            value: 'John',
          ),
        ],
      );
      final masked = masker.mask(tree);
      // Child email should be masked
      expect(masked.children[0].value, isNot(contains('secret@mail.com')));
      // Child name should be preserved (not email/phone/card)
      expect(masked.children[1].value, 'John');
    });
  });

  group('immutability', () {
    test('returns new tree, does not mutate original', () {
      final original = const WidgetDescriptor(
        id: '1', label: 'test@email.com', role: 'textField',
      );
      final masked = masker.mask(original);
      expect(original.label, 'test@email.com'); // unchanged
      expect(masked.label, isNot(contains('test@email.com'))); // masked
    });
  });

  group('custom patterns', () {
    test('custom regex pattern masking', () {
      final customMasker = SensitiveDataMasker(
        extraPatterns: [RegExp(r'SSN-\d{3}-\d{2}-\d{4}')],
      );
      final node = const WidgetDescriptor(
        id: '1', label: 'ID: SSN-123-45-6789', role: 'generic',
      );
      final masked = customMasker.mask(node);
      expect(masked.label, isNot(contains('SSN-123-45-6789')));
    });
  });
}
