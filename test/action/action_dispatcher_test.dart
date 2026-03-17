import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/flutter_agent.dart';

// RED: file doesn't exist yet
// ignore: uri_does_not_exist
import 'package:flutter_agent/src/action/action_dispatcher.dart';

void main() {
  late ActionDispatcher dispatcher;
  late ActionRegistry registry;
  late WidgetDescriptor tree;
  final executedActions = <String>[];

  setUp(() {
    executedActions.clear();
    registry = ActionRegistry();

    // Register mock action handlers using existing API: register(name, fn)
    registry.register('tap', (args) async {
      executedActions.add('tap:${args['id']}');
    });
    registry.register('enterText', (args) async {
      executedActions.add('enterText:${args['id']}:${args['text']}');
    }, parameterSchema: {
      'id': {'type': 'string', 'description': 'Target node ID'},
      'text': {'type': 'string', 'description': 'Text to enter'},
    });
    registry.register('scroll', (args) async {
      executedActions.add('scroll:${args['id']}:${args['direction']}');
    }, parameterSchema: {
      'id': {'type': 'string', 'description': 'Target node ID'},
      'direction': {'type': 'string', 'description': 'Direction'},
    });
    registry.register('setValue', (args) async {
      executedActions.add('setValue:${args['id']}:${args['value']}');
    }, parameterSchema: {
      'id': {'type': 'string', 'description': 'Target node ID'},
      'value': {'type': 'string', 'description': 'Value'},
    });

    tree = WidgetDescriptor(
      id: '1', label: 'Root', role: 'generic',
      children: [
        WidgetDescriptor(
          id: '2', label: 'Login', role: 'button',
          actions: ['tap'],
        ),
        WidgetDescriptor(
          id: '3', label: 'Username', role: 'textField',
          actions: ['tap', 'setText'],
        ),
        WidgetDescriptor(
          id: '4', label: 'Scroll Area', role: 'scrollable',
          actions: ['scrollUp', 'scrollDown'],
        ),
        WidgetDescriptor(
          id: '5', label: 'Volume', role: 'slider',
          value: '50',
          actions: ['setValue'],
        ),
      ],
    );

    dispatcher = ActionDispatcher(registry: registry);
  });

  group('tap dispatch', () {
    test('dispatches tap to resolved node', () async {
      final action = ActionDescriptor(
        actionName: 'tap', args: {'id': '2'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isTrue);
      expect(executedActions, contains('tap:2'));
    });
  });

  group('enterText dispatch', () {
    test('dispatches enterText with value', () async {
      final action = ActionDescriptor(
        actionName: 'enterText', args: {'id': '3', 'text': 'hello'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isTrue);
      expect(executedActions, contains('enterText:3:hello'));
    });
  });

  group('node not found', () {
    test('returns false when node not found', () async {
      final action = ActionDescriptor(
        actionName: 'tap', args: {'id': '999'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isFalse);
      expect(executedActions, isEmpty);
    });
  });

  group('unregistered action', () {
    test('returns false for unregistered action', () async {
      final action = ActionDescriptor(
        actionName: 'delete', args: {'id': '2'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isFalse);
    });
  });

  group('setValue dispatch', () {
    test('handles setValue for slider', () async {
      final action = ActionDescriptor(
        actionName: 'setValue', args: {'id': '5', 'value': '80'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isTrue);
      expect(executedActions, contains('setValue:5:80'));
    });
  });

  group('scroll dispatch', () {
    test('handles scroll with direction', () async {
      final action = ActionDescriptor(
        actionName: 'scroll', args: {'id': '4', 'direction': 'down'},
      );
      final result = await dispatcher.dispatch(action, tree);
      expect(result, isTrue);
      expect(executedActions, contains('scroll:4:down'));
    });
  });
  group('lastError reporting', () {
    test('lastError populated on unregistered action', () async {
      final action = ActionDescriptor(
        actionName: 'delete', args: {'id': '2'},
      );
      await dispatcher.dispatch(action, tree);
      expect(dispatcher.lastError, contains('not registered'));
    });

    test('lastError populated when node not found', () async {
      final action = ActionDescriptor(
        actionName: 'tap', args: {'id': '999'},
      );
      await dispatcher.dispatch(action, tree);
      expect(dispatcher.lastError, contains('not found'));
    });

    test('lastError is null on success', () async {
      final action = ActionDescriptor(
        actionName: 'tap', args: {'id': '2'},
      );
      await dispatcher.dispatch(action, tree);
      expect(dispatcher.lastError, isNull);
    });
  });
}
