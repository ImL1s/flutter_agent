import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/src/models/selector.dart';

void main() {
  group('Selector', () {
    test('creates by id', () {
      final s = Selector.byId('42');
      expect(s.by, SelectorType.id);
      expect(s.value, '42');
    });

    test('creates by label', () {
      final s = Selector.byLabel('Submit');
      expect(s.by, SelectorType.label);
      expect(s.value, 'Submit');
    });

    test('fromJson parses correctly', () {
      final s = Selector.fromJson({'by': 'label', 'value': 'OK'});
      expect(s.by, SelectorType.label);
      expect(s.value, 'OK');
    });

    test('fromJson defaults to id for unknown type', () {
      final s = Selector.fromJson({'by': 'unknown', 'value': '1'});
      expect(s.by, SelectorType.id);
    });

    test('fromJson handles role type', () {
      final s = Selector.fromJson({'by': 'role', 'value': 'button'});
      expect(s.by, SelectorType.role);
    });

    test('fromJson handles key type', () {
      final s = Selector.fromJson({'by': 'key', 'value': 'myKey'});
      expect(s.by, SelectorType.key);
    });

    test('toJson produces expected format', () {
      const s = Selector(by: SelectorType.label, value: 'OK');
      final json = s.toJson();
      expect(json['by'], 'label');
      expect(json['value'], 'OK');
    });

    test('equality works', () {
      const a = Selector(by: SelectorType.id, value: '1');
      const b = Selector(by: SelectorType.id, value: '1');
      const c = Selector(by: SelectorType.label, value: '1');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString is readable', () {
      const s = Selector(by: SelectorType.label, value: 'OK');
      expect(s.toString(), contains('label'));
      expect(s.toString(), contains('OK'));
    });
  });
}
