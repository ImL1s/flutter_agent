/// Represents the current status of the agent.
enum AgentStatus {
  /// Agent is initialized but not running.
  idle,

  /// Agent is actively processing a task.
  running,

  /// Agent was manually paused/stopped.
  paused,

  /// Agent completed its task successfully.
  completed,

  /// Agent encountered an unrecoverable error.
  error,
}

/// Mutable state of the running [AgentCore].
class AgentState {
  /// Current execution status.
  AgentStatus status;

  /// Number of loop iterations completed.
  int stepCount;

  /// Last error message, if any.
  String? lastError;

  AgentState({
    this.status = AgentStatus.idle,
    this.stepCount = 0,
    this.lastError,
  });

  @override
  String toString() =>
      'AgentState(status=$status, steps=$stepCount, error=$lastError)';
}
