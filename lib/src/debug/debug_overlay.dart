import 'dart:async';

/// Streams agent debug events for UI binding.
///
/// Attach this to an [AgentCallbacks] to receive real-time events
/// that can be displayed in a debug overlay.
class DebugLogStream {
  final StreamController<DebugEvent> _controller =
      StreamController<DebugEvent>.broadcast();

  /// Stream of debug events.
  Stream<DebugEvent> get stream => _controller.stream;

  /// Emit a step start event.
  void stepStarted(int step, int maxSteps) {
    _controller.add(DebugEvent(
      type: DebugEventType.stepStart,
      message: 'Step $step/$maxSteps',
      timestamp: DateTime.now(),
    ));
  }

  /// Emit an action executed event.
  void actionExecuted(String actionName, bool success) {
    _controller.add(DebugEvent(
      type: success ? DebugEventType.actionSuccess : DebugEventType.actionFailure,
      message: '$actionName: ${success ? "OK" : "FAILED"}',
      timestamp: DateTime.now(),
    ));
  }

  /// Emit a completion event.
  void completed(String status) {
    _controller.add(DebugEvent(
      type: DebugEventType.completed,
      message: 'Agent $status',
      timestamp: DateTime.now(),
    ));
  }

  /// Emit an error event.
  void error(Object error) {
    _controller.add(DebugEvent(
      type: DebugEventType.error,
      message: 'Error: $error',
      timestamp: DateTime.now(),
    ));
  }

  /// Close the stream.
  void dispose() => _controller.close();
}

/// Types of debug events.
enum DebugEventType {
  stepStart,
  actionSuccess,
  actionFailure,
  completed,
  error,
}

/// A single debug event with metadata.
class DebugEvent {
  final DebugEventType type;
  final String message;
  final DateTime timestamp;

  const DebugEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${type.name}: $message';
}
