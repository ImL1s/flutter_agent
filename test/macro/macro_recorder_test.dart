import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/flutter_agent.dart';

void main() {
  group('MacroRecorder', () {
    test('records actions and builds macro', () {
      final recorder = MacroRecorder();
      recorder.record(const ActionDescriptor(actionName: 'tap', args: {'id': '1'}));
      recorder.record(const ActionDescriptor(actionName: 'setText', args: {'id': '2', 'text': 'hello'}));

      expect(recorder.length, 2);
      final macro = recorder.toMacro('Login Flow');
      expect(macro.name, 'Login Flow');
      expect(macro.length, 2);
      expect(macro.actions.first.actionName, 'tap');
    });

    test('clear removes all recorded actions', () {
      final recorder = MacroRecorder();
      recorder.record(const ActionDescriptor(actionName: 'tap', args: {}));
      expect(recorder.length, 1);
      recorder.clear();
      expect(recorder.length, 0);
    });

    test('empty recorder produces empty macro', () {
      final recorder = MacroRecorder();
      final macro = recorder.toMacro('Empty');
      expect(macro.length, 0);
      expect(macro.name, 'Empty');
    });
  });

  group('Macro serialization', () {
    test('toJson and fromJson roundtrip', () {
      final original = Macro(
        name: 'Test Macro',
        actions: [
          const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          const ActionDescriptor(actionName: 'scroll', args: {'direction': 'up'}),
        ],
      );

      final json = original.toJson();
      final restored = Macro.fromJson(json);

      expect(restored.name, 'Test Macro');
      expect(restored.length, 2);
      expect(restored.actions[0].actionName, 'tap');
      expect(restored.actions[1].args['direction'], 'up');
    });

    test('MacroStore serialize/deserialize roundtrip', () {
      final original = Macro(
        name: 'Store Test',
        actions: [
          const ActionDescriptor(actionName: 'tap', args: {'id': '5'}),
        ],
      );

      final jsonString = MacroStore.serialize(original);
      final restored = MacroStore.deserialize(jsonString);

      expect(restored.name, 'Store Test');
      expect(restored.actions.first.args['id'], '5');
    });
  });
}
