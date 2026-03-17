import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/src/models/widget_descriptor.dart';

void main() {
  group('WidgetDescriptor', () {
    test('creates with required fields', () {
      const desc = WidgetDescriptor(
        id: '1',
        role: 'button',
        label: 'Submit',
      );
      expect(desc.id, '1');
      expect(desc.role, 'button');
      expect(desc.label, 'Submit');
      expect(desc.hint, '');
      expect(desc.value, '');
      expect(desc.actions, isEmpty);
      expect(desc.children, isEmpty);
    });

    test('creates with all fields', () {
      const desc = WidgetDescriptor(
        id: '2',
        role: 'textField',
        label: 'Name',
        hint: 'Enter your name',
        value: 'John',
        actions: ['tap', 'setText'],
      );
      expect(desc.hint, 'Enter your name');
      expect(desc.value, 'John');
      expect(desc.actions, ['tap', 'setText']);
    });

    test('toJson omits empty optional fields', () {
      const desc = WidgetDescriptor(
        id: '1',
        role: 'button',
        label: 'OK',
      );
      final json = desc.toJson();
      expect(json['id'], '1');
      expect(json['role'], 'button');
      expect(json['label'], 'OK');
      expect(json.containsKey('hint'), false);
      expect(json.containsKey('value'), false);
      expect(json.containsKey('actions'), false);
      expect(json.containsKey('children'), false);
    });

    test('toJson includes non-empty optional fields', () {
      const desc = WidgetDescriptor(
        id: '1',
        role: 'slider',
        label: 'Volume',
        value: '50',
        actions: ['increase', 'decrease'],
      );
      final json = desc.toJson();
      expect(json['value'], '50');
      expect(json['actions'], ['increase', 'decrease']);
    });

    test('toJson serializes children recursively', () {
      const child = WidgetDescriptor(
        id: '2',
        role: 'button',
        label: 'Child',
      );
      const parent = WidgetDescriptor(
        id: '1',
        role: 'generic',
        label: 'Parent',
        children: [child],
      );
      final json = parent.toJson();
      expect(json['children'], isList);
      final childJson = (json['children'] as List).first as Map;
      expect(childJson['id'], '2');
      expect(childJson['label'], 'Child');
    });

    test('copyWith creates modified copy', () {
      const original = WidgetDescriptor(
        id: '1',
        role: 'button',
        label: 'OK',
      );
      final copy = original.copyWith(label: 'Cancel', value: 'new');
      expect(copy.id, '1');
      expect(copy.label, 'Cancel');
      expect(copy.value, 'new');
    });

    test('equality based on core fields', () {
      const a = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      const b = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      const c = WidgetDescriptor(id: '2', role: 'button', label: 'OK');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString provides useful output', () {
      const desc = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      expect(desc.toString(), contains('button'));
      expect(desc.toString(), contains('OK'));
    });
  });
}
