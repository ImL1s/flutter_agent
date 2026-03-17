import 'package:flutter_test/flutter_test.dart';

// RED: file doesn't exist yet
// ignore: uri_does_not_exist
import 'package:ai_flutter_agent/src/llm/retry_executor.dart';

void main() {
  group('succeeds on first try', () {
    test('returns result without retry', () async {
      final executor = RetryExecutor(maxAttempts: 3);
      final result = await executor.execute(() async => 'hello');
      expect(result, 'hello');
    });
  });

  group('retries on failure', () {
    test('retries and succeeds on second attempt', () async {
      int attempts = 0;
      final executor = RetryExecutor(
        maxAttempts: 3,
        initialDelay: Duration.zero, // no delay for tests
      );
      final result = await executor.execute(() async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return 'success';
      });
      expect(result, 'success');
      expect(attempts, 2);
    });

    test('retries and succeeds on third attempt', () async {
      int attempts = 0;
      final executor = RetryExecutor(
        maxAttempts: 3,
        initialDelay: Duration.zero,
      );
      final result = await executor.execute(() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'done';
      });
      expect(result, 'done');
      expect(attempts, 3);
    });
  });

  group('exhausted retries', () {
    test('throws after maxAttempts exhausted', () async {
      final executor = RetryExecutor(
        maxAttempts: 2,
        initialDelay: Duration.zero,
      );
      expect(
        () => executor.execute(() async => throw Exception('always fail')),
        throwsException,
      );
    });
  });

  group('onRetry callback', () {
    test('calls onRetry on each retry', () async {
      final retries = <int>[];
      final executor = RetryExecutor(
        maxAttempts: 3,
        initialDelay: Duration.zero,
        onRetry: (attempt, error) => retries.add(attempt),
      );
      int attempts = 0;
      await executor.execute(() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'ok';
      });
      // onRetry called for attempt 1 and 2 (before retry 2 and 3)
      expect(retries, [1, 2]);
    });
  });

  group('backoff behavior', () {
    test('applies delay between retries', () async {
      final executor = RetryExecutor(
        maxAttempts: 2,
        initialDelay: const Duration(milliseconds: 50),
        backoffMultiplier: 2.0,
      );
      int attempts = 0;
      final sw = Stopwatch()..start();
      await executor.execute(() async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return 'ok';
      });
      sw.stop();
      // Should have waited at least 50ms (first retry delay)
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });
}
