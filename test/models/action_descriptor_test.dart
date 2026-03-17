import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/src/models/action_descriptor.dart';

void main() {
  group('ActionDescriptor', () {
    test('creates with required actionName', () {
      const desc = ActionDescriptor(actionName: 'tap');
      expect(desc.actionName, 'tap');
      expect(desc.args, isEmpty);
    });

    test('creates with args', () {
      const desc = ActionDescriptor(
        actionName: 'enterText',
        args: {'id': '5', 'text': 'Hello'},
      );
      expect(desc.actionName, 'enterText');
      expect(desc.args['text'], 'Hello');
    });

    test('fromJson parses action format', () {
      final desc = ActionDescriptor.fromJson({
        'action': 'scroll',
        'args': {'direction': 'down'},
      });
      expect(desc.actionName, 'scroll');
      expect(desc.args['direction'], 'down');
    });

    test('fromJson handles missing args', () {
      final desc = ActionDescriptor.fromJson({'action': 'tap'});
      expect(desc.actionName, 'tap');
      expect(desc.args, isEmpty);
    });

    test('fromToolCall parses OpenAI format', () {
      final desc = ActionDescriptor.fromToolCall({
        'name': 'tap',
        'arguments': {'id': '42'},
      });
      expect(desc.actionName, 'tap');
      expect(desc.args['id'], '42');
    });

    test('toJson produces expected format', () {
      const desc = ActionDescriptor(
        actionName: 'tap',
        args: {'id': '1'},
      );
      final json = desc.toJson();
      expect(json['action'], 'tap');
      expect((json['args'] as Map)['id'], '1');
    });

    test('toString is readable', () {
      const desc = ActionDescriptor(actionName: 'tap', args: {'id': '1'});
      expect(desc.toString(), contains('tap'));
    });
  });
}
