import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/src/executor/executor.dart';
import 'package:ai_flutter_agent/src/action/action_registry.dart';
import 'package:ai_flutter_agent/src/audit/audit_log.dart';
import 'package:ai_flutter_agent/src/models/action_descriptor.dart';

void main() {
  late ActionRegistry registry;
  late AuditLog auditLog;
  late Executor executor;

  setUp(() {
    registry = ActionRegistry();
    auditLog = AuditLog();
    executor = Executor(actionRegistry: registry, auditLog: auditLog);
  });

  group('Executor', () {
    test('executeSingle runs registered action and logs success', () async {
      var called = false;
      registry.register('tap', (args) async {
        called = true;
      });

      const action = ActionDescriptor(actionName: 'tap', args: {'id': '1'});
      final result = await executor.executeSingle(action);

      expect(result.success, true);
      expect(result.error, isNull);
      expect(called, true);
      expect(auditLog.length, 1);
      expect(auditLog.entries.first.success, true);
    });

    test('executeSingle rejects unregistered action (whitelist)', () async {
      const action = ActionDescriptor(actionName: 'deleteAll', args: {});
      final result = await executor.executeSingle(action);

      expect(result.success, false);
      expect(result.error, contains('whitelist'));
      expect(auditLog.length, 1);
      expect(auditLog.entries.first.success, false);
    });

    test('executeSingle handles action exceptions', () async {
      registry.register('tap', (args) async {
        throw Exception('Something broke');
      });

      const action = ActionDescriptor(actionName: 'tap', args: {});
      final result = await executor.executeSingle(action);

      expect(result.success, false);
      expect(result.error, contains('Something broke'));
      expect(auditLog.failures.length, 1);
    });

    test('executeAll runs actions sequentially', () async {
      final order = <String>[];
      registry.register('tap', (args) async {
        order.add('tap');
      });
      registry.register('scroll', (args) async {
        order.add('scroll');
      });

      final actions = [
        const ActionDescriptor(actionName: 'tap', args: {}),
        const ActionDescriptor(actionName: 'scroll', args: {}),
      ];

      final results = await executor.executeAll(actions);

      expect(results, hasLength(2));
      expect(results.every((r) => r.success), true);
      expect(order, ['tap', 'scroll']);
    });

    test('executeAll stops on first failure', () async {
      registry.register('tap', (args) async {
        throw Exception('fail');
      });
      registry.register('scroll', (args) async {});

      final actions = [
        const ActionDescriptor(actionName: 'tap', args: {}),
        const ActionDescriptor(actionName: 'scroll', args: {}),
      ];

      final results = await executor.executeAll(actions);

      expect(results, hasLength(1)); // stopped after first
      expect(results.first.success, false);
    });

    test('audit log records all executions', () async {
      registry.register('tap', (args) async {});

      await executor.executeSingle(
          const ActionDescriptor(actionName: 'tap', args: {}));
      await executor.executeSingle(
          const ActionDescriptor(actionName: 'unknown', args: {}));
      await executor.executeSingle(
          const ActionDescriptor(actionName: 'tap', args: {}));

      expect(auditLog.length, 3);
      expect(auditLog.failures.length, 1);
    });
  });
}
