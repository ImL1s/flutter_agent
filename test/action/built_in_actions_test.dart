import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

void main() {
  group('BuiltInActions', () {
    test('registerDefaults registers all standard actions', () {
      final registry = ActionRegistry();
      BuiltInActions.registerDefaults(registry);

      expect(registry.has('tap'), isTrue);
      expect(registry.has('longPress'), isTrue);
      expect(registry.has('scrollUp'), isTrue);
      expect(registry.has('scrollDown'), isTrue);
      expect(registry.has('scrollLeft'), isTrue);
      expect(registry.has('scrollRight'), isTrue);
      expect(registry.has('focus'), isTrue);
      expect(registry.has('dismiss'), isTrue);
      expect(registry.has('setText'), isTrue);
    });

    test('allActionNames returns all built-in names', () {
      final names = BuiltInActions.allActionNames;
      expect(names, containsAll(['tap', 'longPress', 'setText']));
      expect(names.length, 9);
    });

    test('tool schemas have correct structure', () {
      final registry = ActionRegistry();
      BuiltInActions.registerDefaults(registry);
      final schemas = registry.toToolSchemas();

      expect(schemas.length, 9);
      for (final schema in schemas) {
        expect(schema['type'], 'function');
        expect(schema['function']['name'], isA<String>());
        expect(schema['function']['parameters'], isA<Map>());
      }
    });

    test('tap action calls performAction callback', () async {
      final registry = ActionRegistry();
      SemanticsAction? captured;
      int? capturedId;

      BuiltInActions.registerDefaults(
        registry,
        performAction: (nodeId, action, {Object? actionArgs}) async {
          capturedId = nodeId;
          captured = action;
        },
      );

      await registry.execute('tap', {'id': '42'});

      expect(capturedId, 42);
      expect(captured, SemanticsAction.tap);
    });

    test('longPress action calls with correct SemanticsAction', () async {
      final registry = ActionRegistry();
      SemanticsAction? captured;

      BuiltInActions.registerDefaults(
        registry,
        performAction: (_, action, {Object? actionArgs}) async => captured = action,
      );

      await registry.execute('longPress', {'id': '1'});
      expect(captured, SemanticsAction.longPress);
    });

    test('unregister removes a built-in action', () {
      final registry = ActionRegistry();
      BuiltInActions.registerDefaults(registry);

      expect(registry.has('tap'), isTrue);
      registry.unregister('tap');
      expect(registry.has('tap'), isFalse);
    });
  });

  group('SemanticsActionExecutor (static)', () {
    test('isSupported returns true for known actions', () {
      expect(SemanticsActionExecutor.isSupported('tap'), isTrue);
      expect(SemanticsActionExecutor.isSupported('longPress'), isTrue);
      expect(SemanticsActionExecutor.isSupported('unknown'), isFalse);
    });

    test('supportedActions lists all known names', () {
      final actions = SemanticsActionExecutor.supportedActions;
      expect(actions, containsAll(['tap', 'scrollUp', 'setText']));
    });

    test('UnsupportedActionException has correct message', () {
      final ex = UnsupportedActionException('fly');
      expect(ex.toString(), contains('fly'));
      expect(ex.toString(), contains('not a supported'));
    });
  });
}
