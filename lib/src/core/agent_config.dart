/// Configuration for the [AgentCore].
class AgentConfig {
  /// Maximum number of perceive→plan→execute→verify steps.
  final int maxSteps;

  /// Number of unchanged-state retries before giving up.
  final int maxRetries;

  /// Delay between agent loop steps (to let UI settle).
  final Duration stepDelay;

  /// Enable debug logging to console.
  final bool debugMode;

  const AgentConfig({
    this.maxSteps = 20,
    this.maxRetries = 3,
    this.stepDelay = const Duration(milliseconds: 500),
    this.debugMode = false,
  });
}
