import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/flutter_agent.dart';

void main() {
  group('default values', () {
    test('default values are sensible', () {
      const config = AgentConfig();
      expect(config.maxSteps, 20);
      expect(config.maxRetries, 3);
      expect(config.stepDelay, const Duration(milliseconds: 500));
      expect(config.debugMode, false);
      expect(config.timeout, const Duration(seconds: 30));
      expect(config.enableDataMasking, true);
      expect(config.conversationMaxTurns, 20);
    });
  });

  group('custom values', () {
    test('custom values override defaults', () {
      const config = AgentConfig(
        maxSteps: 5,
        maxRetries: 1,
        stepDelay: Duration(seconds: 1),
        debugMode: true,
        timeout: Duration(seconds: 60),
        enableDataMasking: false,
        conversationMaxTurns: 10,
      );
      expect(config.maxSteps, 5);
      expect(config.maxRetries, 1);
      expect(config.stepDelay, const Duration(seconds: 1));
      expect(config.debugMode, true);
      expect(config.timeout, const Duration(seconds: 60));
      expect(config.enableDataMasking, false);
      expect(config.conversationMaxTurns, 10);
    });
  });

  group('timeout', () {
    test('timeout defaults to 30 seconds', () {
      const config = AgentConfig();
      expect(config.timeout.inSeconds, 30);
    });
  });

  group('data masking', () {
    test('data masking defaults to true', () {
      const config = AgentConfig();
      expect(config.enableDataMasking, isTrue);
    });
  });

  group('copyWith', () {
    test('creates modified copy', () {
      const original = AgentConfig(maxSteps: 10, debugMode: false);
      final modified = original.copyWith(debugMode: true, maxSteps: 50);
      expect(modified.debugMode, true);
      expect(modified.maxSteps, 50);
      // Unchanged values preserved
      expect(modified.maxRetries, 3);
      expect(modified.timeout, const Duration(seconds: 30));
    });

    test('copyWith with no args returns equivalent config', () {
      const original = AgentConfig(maxSteps: 7);
      final copy = original.copyWith();
      expect(copy.maxSteps, 7);
      expect(copy.maxRetries, original.maxRetries);
    });
  });
}
