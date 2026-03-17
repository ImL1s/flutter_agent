import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

/// Concrete test implementation of StreamingLLMClient.
class TestStreamingClient extends StreamingLLMClient {
  final List<ActionDescriptor> streamedActions;
  final List<ActionDescriptor> nonStreamedActions;

  TestStreamingClient({
    this.streamedActions = const [],
    this.nonStreamedActions = const [],
  });

  @override
  Stream<ActionDescriptor> requestActionsStream({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  }) async* {
    for (final action in streamedActions) {
      yield action;
    }
  }

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  }) async {
    return nonStreamedActions;
  }
}

void main() {
  group('StreamingLLMClient', () {
    test('streams action descriptors one at a time', () async {
      final client = TestStreamingClient(
        streamedActions: [
          const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          const ActionDescriptor(actionName: 'enterText', args: {'id': '2', 'text': 'hello'}),
        ],
      );

      final received = <ActionDescriptor>[];
      await for (final action in client.requestActionsStream(
        prompt: 'Test prompt',
        toolSchemas: [],
      )) {
        received.add(action);
      }

      expect(received, hasLength(2));
      expect(received[0].actionName, 'tap');
      expect(received[1].actionName, 'enterText');
    });

    test('can fallback to non-streaming requestActions', () async {
      final client = TestStreamingClient(
        nonStreamedActions: [
          const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
        ],
      );

      final result = await client.requestActions(
        prompt: 'Test',
        toolSchemas: [],
      );

      expect(result, hasLength(1));
      expect(result.first.actionName, 'tap');
    });

    test('empty stream yields no actions', () async {
      final client = TestStreamingClient();

      final received = <ActionDescriptor>[];
      await for (final action in client.requestActionsStream(
        prompt: 'Test',
        toolSchemas: [],
      )) {
        received.add(action);
      }

      expect(received, isEmpty);
    });

    test('is a subtype of LLMClient', () {
      final client = TestStreamingClient();
      expect(client, isA<LLMClient>());
      expect(client, isA<StreamingLLMClient>());
    });
  });
}
