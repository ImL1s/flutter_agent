import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/src/action/action_registry.dart';

void main() {
  group('ActionRegistry', () {
    late ActionRegistry registry;

    setUp(() {
      registry = ActionRegistry();
    });

    test('starts with no actions', () {
      expect(registry.registeredActions, isEmpty);
      expect(registry.has('tap'), false);
    });

    test('register adds action', () {
      registry.register('tap', (_) async {});
      expect(registry.has('tap'), true);
      expect(registry.registeredActions, contains('tap'));
    });

    test('unregister removes action', () {
      registry.register('tap', (_) async {});
      registry.unregister('tap');
      expect(registry.has('tap'), false);
    });

    test('execute runs registered action', () async {
      var called = false;
      Map<String, dynamic>? receivedArgs;
      registry.register('tap', (args) async {
        called = true;
        receivedArgs = args;
      });
      await registry.execute('tap', {'id': '42'});
      expect(called, true);
      expect(receivedArgs!['id'], '42');
    });

    test('execute throws UnregisteredActionException for unknown action',
        () async {
      expect(
        () => registry.execute('unknown', {}),
        throwsA(isA<UnregisteredActionException>()),
      );
    });

    test('toToolSchemas exports correct format', () {
      registry.register('tap', (_) async {},
          description: 'Tap a UI element.');
      final schemas = registry.toToolSchemas();
      expect(schemas, hasLength(1));
      final schema = schemas.first;
      expect(schema['type'], 'function');
      final fn = schema['function'] as Map;
      expect(fn['name'], 'tap');
      expect(fn['description'], 'Tap a UI element.');
      expect((fn['parameters'] as Map)['type'], 'object');
    });

    test('toToolSchemas includes custom parameter schema', () {
      registry.register(
        'enterText',
        (_) async {},
        parameterSchema: {
          'id': {'type': 'string', 'description': 'Node ID'},
          'text': {'type': 'string', 'description': 'Text to enter'},
        },
      );
      final schemas = registry.toToolSchemas();
      final fn = schemas.first['function'] as Map;
      final params = fn['parameters'] as Map;
      final props = params['properties'] as Map;
      expect(props.containsKey('id'), true);
      expect(props.containsKey('text'), true);
      expect((params['required'] as List), contains('text'));
    });

    test('multiple actions registered correctly', () {
      registry.register('tap', (_) async {});
      registry.register('scroll', (_) async {});
      registry.register('enterText', (_) async {});
      expect(registry.registeredActions.length, 3);
    });

    test('UnregisteredActionException has readable message', () {
      final ex = UnregisteredActionException('badAction');
      expect(ex.toString(), contains('badAction'));
      expect(ex.toString(), contains('whitelist'));
    });
  });
}
