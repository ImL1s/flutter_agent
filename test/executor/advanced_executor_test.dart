import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

void main() {
  group('Action Confirmation Hook', () {
    test('confirmable actions require confirmation callback', () async {
      final confirmed = <String>[];
      final denied = <String>[];

      final registry = ActionRegistry();
      registry.register('tap', (_) async {});
      registry.register('deleteAccount', (_) async {});

      final executor = Executor(
        actionRegistry: registry,
        auditLog: AuditLog(),
        actionConfirmation: (action) async {
          if (action.actionName == 'deleteAccount') {
            denied.add(action.actionName);
            return false;
          }
          confirmed.add(action.actionName);
          return true;
        },
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
        const ActionDescriptor(actionName: 'deleteAccount', args: {}),
      ]);

      expect(confirmed, ['tap']);
      expect(denied, ['deleteAccount']);
      expect(results[0].success, isTrue);
      expect(results[1].success, isFalse);
    });

    test('works without confirmation hook', () async {
      final registry = ActionRegistry();
      registry.register('tap', (_) async {});
      final executor = Executor(
        actionRegistry: registry,
        auditLog: AuditLog(),
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
      ]);
      expect(results.first.success, isTrue);
    });
  });

  group('Timeout Enforcement', () {
    test('AgentConfig.timeout is respected in executor', () async {
      final registry = ActionRegistry();
      registry.register('slowAction', (_) async {
        await Future.delayed(const Duration(seconds: 5));
      });

      final executor = Executor(
        actionRegistry: registry,
        auditLog: AuditLog(),
        actionTimeout: const Duration(milliseconds: 100),
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'slowAction', args: {}),
      ]);

      expect(results.first.success, isFalse);
      expect(results.first.error, contains('TimeoutException'));
    });

    test('actions within timeout succeed', () async {
      final registry = ActionRegistry();
      registry.register('fastAction', (_) async {});

      final executor = Executor(
        actionRegistry: registry,
        auditLog: AuditLog(),
        actionTimeout: const Duration(seconds: 5),
      );

      final results = await executor.executeAll([
        const ActionDescriptor(actionName: 'fastAction', args: {}),
      ]);

      expect(results.first.success, isTrue);
    });
  });
}
