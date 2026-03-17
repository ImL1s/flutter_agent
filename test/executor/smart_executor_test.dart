import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/flutter_agent.dart';

void main() {
  late ActionRegistry registry;
  late AuditLog auditLog;
  final executedActions = <String>[];

  const tree = WidgetDescriptor(
    id: '1', role: 'generic', label: 'Root',
    children: [
      WidgetDescriptor(id: '2', role: 'button', label: 'Login'),
      WidgetDescriptor(id: '3', role: 'textField', label: 'Username'),
    ],
  );

  setUp(() {
    executedActions.clear();
    registry = ActionRegistry();
    auditLog = AuditLog();
    registry.register('tap', (args) async {
      executedActions.add('tap:${args['id']}');
    });
    registry.register('enterText', (args) async {
      executedActions.add('enterText:${args['id']}:${args['text']}');
    });
  });

  group('Executor with ActionDispatcher', () {
    test('resolves nodes via dispatcher before execution', () async {
      final dispatcher = ActionDispatcher(registry: registry);
      final executor = Executor(
        actionRegistry: registry,
        auditLog: auditLog,
        actionDispatcher: dispatcher,
        uiTree: tree,
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'tap', args: {'id': '2'}),
      ]);

      expect(results.first.success, isTrue);
      expect(executedActions, contains('tap:2'));
    });

    test('fails when dispatcher finds node missing', () async {
      final dispatcher = ActionDispatcher(registry: registry);
      final executor = Executor(
        actionRegistry: registry,
        auditLog: auditLog,
        actionDispatcher: dispatcher,
        uiTree: tree,
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'tap', args: {'id': '999'}),
      ]);

      expect(results.first.success, isFalse);
      expect(executedActions, isEmpty);
    });

    test('works without dispatcher (backward compatible)', () async {
      final executor = Executor(
        actionRegistry: registry,
        auditLog: auditLog,
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'tap', args: {'id': '2'}),
      ]);

      expect(results.first.success, isTrue);
      expect(executedActions, contains('tap:2'));
    });
  });
}
