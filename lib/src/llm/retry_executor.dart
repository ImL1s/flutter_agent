/// Executes an async function with automatic retry and exponential backoff.
///
/// ```dart
/// final executor = RetryExecutor(
///   maxRetries: 3,
///   initialDelay: Duration(milliseconds: 500),
/// );
/// final result = await executor.execute(() => llmClient.requestActions(...));
/// ```
class RetryExecutor {
  /// Maximum number of total attempts (including the first try).
  final int maxAttempts;

  /// Delay before the first retry.
  final Duration initialDelay;

  /// Multiplier applied to delay after each retry.
  final double backoffMultiplier;

  /// Optional callback invoked before each retry.
  final void Function(int attempt, Object error)? onRetry;

  const RetryExecutor({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.onRetry,
  });

  /// Execute [fn] with retry logic.
  ///
  /// Retries up to [maxRetries] times on failure, applying exponential
  /// backoff between attempts.
  Future<T> execute<T>(Future<T> Function() fn) async {
    var delay = initialDelay;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        onRetry?.call(attempt, e);
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
    // Unreachable but satisfies the compiler
    throw StateError('RetryExecutor: unreachable');
  }
}
