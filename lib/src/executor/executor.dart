import '../models/action_descriptor.dart';
import '../action/action_registry.dart';
import '../audit/audit_log.dart';

/// Result of executing a single action.
class ExecutionResult {
  /// The action that was attempted.
  final ActionDescriptor action;

  /// Whether execution succeeded.
  final bool success;

  /// Error message if execution failed.
  final String? error;

  ExecutionResult({
    required this.action,
    required this.success,
    this.error,
  });

  @override
  String toString() =>
      'ExecutionResult(action=${action.actionName}, success=$success'
      '${error != null ? ", error=$error" : ""})';
}

/// Executes [ActionDescriptor]s against the [ActionRegistry].
///
/// The [Executor] enforces the action whitelist — any action not in the
/// registry is rejected and logged. All executions (success and failure)
/// are recorded in the [AuditLog].
class Executor {
  final ActionRegistry actionRegistry;
  final AuditLog auditLog;

  Executor({required this.actionRegistry, required this.auditLog});

  /// Execute a list of action descriptors sequentially.
  ///
  /// Stops on the first failure and returns all results up to that point.
  Future<List<ExecutionResult>> executeAll(
      List<ActionDescriptor> actions) async {
    final results = <ExecutionResult>[];
    for (final action in actions) {
      final result = await executeSingle(action);
      results.add(result);
      if (!result.success) break;
    }
    return results;
  }

  /// Execute a single action descriptor.
  ///
  /// Checks the whitelist, executes the action, and logs the result.
  Future<ExecutionResult> executeSingle(ActionDescriptor action) async {
    final timestamp = DateTime.now();
    try {
      // Whitelist enforcement
      if (!actionRegistry.has(action.actionName)) {
        final msg =
            'Action "${action.actionName}" not in whitelist. Skipped.';
        auditLog.log(
          action: action.actionName,
          args: action.args,
          timestamp: timestamp,
          success: false,
          error: msg,
        );
        return ExecutionResult(action: action, success: false, error: msg);
      }

      // Execute the action
      await actionRegistry.execute(action.actionName, action.args);

      // Log success
      auditLog.log(
        action: action.actionName,
        args: action.args,
        timestamp: timestamp,
        success: true,
      );
      return ExecutionResult(action: action, success: true);
    } catch (e) {
      // Log failure
      auditLog.log(
        action: action.actionName,
        args: action.args,
        timestamp: timestamp,
        success: false,
        error: e.toString(),
      );
      return ExecutionResult(
          action: action, success: false, error: e.toString());
    }
  }
}
