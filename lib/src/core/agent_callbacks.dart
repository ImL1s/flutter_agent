import '../models/widget_descriptor.dart';
import '../models/action_descriptor.dart';

/// Callback hooks for observing [AgentCore] execution.
///
/// Implement these callbacks to monitor agent progress, log metrics,
/// display progress UI, or integrate with analytics.
///
/// ```dart
/// final callbacks = AgentCallbacks(
///   onStepStart: (step, total) => print('Step $step/$total'),
///   onActionExecuted: (action, success) => analytics.log(action),
///   onError: (error) => crashlytics.report(error),
/// );
/// ```
class AgentCallbacks {
  /// Called at the beginning of each perceive→plan→execute→verify step.
  final void Function(int step, int maxSteps)? onStepStart;

  /// Called after each step completes (after verification).
  final void Function(int step, WidgetDescriptor? uiState)? onStepComplete;

  /// Called after each individual action is executed.
  final void Function(ActionDescriptor action, bool success)? onActionExecuted;

  /// Called when the agent loop ends (complete, error, or paused).
  final void Function(String reason)? onComplete;

  /// Called when an error occurs during the loop.
  final void Function(Object error)? onError;

  const AgentCallbacks({
    this.onStepStart,
    this.onStepComplete,
    this.onActionExecuted,
    this.onComplete,
    this.onError,
  });
}
