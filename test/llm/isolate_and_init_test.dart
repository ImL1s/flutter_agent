import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';
import 'package:ai_flutter_agent/src/llm/isolate_llm_client.dart';

/// Simple in-memory LLM client for testing.
class FakeLLMClient implements LLMClient {
  final List<ActionDescriptor> result;
  FakeLLMClient({this.result = const []});

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  }) async {
    return result;
  }
}

void main() {
  group('IsolateLLMClient', () {
    test('delegates to inner client and returns results', () async {
      final client = IsolateLLMClient(
        factory: () => FakeLLMClient(
          result: [const ActionDescriptor(actionName: 'tap', args: {'id': '1'})],
        ),
      );

      final actions = await client.requestActions(
        prompt: 'Test',
        toolSchemas: [],
      );

      expect(actions, hasLength(1));
      expect(actions.first.actionName, 'tap');
    });

    test('is a subtype of LLMClient', () {
      final client = IsolateLLMClient(
        factory: () => FakeLLMClient(),
      );
      expect(client, isA<LLMClient>());
    });

    test('handles empty results', () async {
      final client = IsolateLLMClient(
        factory: () => FakeLLMClient(),
      );

      final actions = await client.requestActions(
        prompt: 'Test',
        toolSchemas: [],
      );

      expect(actions, isEmpty);
    });
  });

  group('AgentCore.initialize convenience', () {
    test('creates a configured AgentCore with defaults', () {
      const config = AgentConfig();
      expect(config.maxSteps, 20);
      expect(config.enableDataMasking, isTrue);
      expect(config.conversationMaxTurns, 20);
    });

    test('AgentConfig.copyWith overrides selectively', () {
      const base = AgentConfig(maxSteps: 5);
      final modified = base.copyWith(enableDataMasking: false);

      expect(modified.maxSteps, 5);
      expect(modified.enableDataMasking, isFalse);
    });

    test('AgentConfig timeout defaults to 30 seconds', () {
      const config = AgentConfig();
      expect(config.timeout, const Duration(seconds: 30));
    });
  });
}
