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

  /// Timeout for individual LLM requests.
  final Duration timeout;

  /// Whether to mask sensitive data before sending to the LLM.
  final bool enableDataMasking;

  /// Maximum conversation history turns to retain.
  final int conversationMaxTurns;

  const AgentConfig({
    this.maxSteps = 20,
    this.maxRetries = 3,
    this.stepDelay = const Duration(milliseconds: 500),
    this.debugMode = false,
    this.timeout = const Duration(seconds: 30),
    this.enableDataMasking = true,
    this.conversationMaxTurns = 20,
  });

  /// Create a copy with selected fields overridden.
  AgentConfig copyWith({
    int? maxSteps,
    int? maxRetries,
    Duration? stepDelay,
    bool? debugMode,
    Duration? timeout,
    bool? enableDataMasking,
    int? conversationMaxTurns,
  }) {
    return AgentConfig(
      maxSteps: maxSteps ?? this.maxSteps,
      maxRetries: maxRetries ?? this.maxRetries,
      stepDelay: stepDelay ?? this.stepDelay,
      debugMode: debugMode ?? this.debugMode,
      timeout: timeout ?? this.timeout,
      enableDataMasking: enableDataMasking ?? this.enableDataMasking,
      conversationMaxTurns: conversationMaxTurns ?? this.conversationMaxTurns,
    );
  }
}
