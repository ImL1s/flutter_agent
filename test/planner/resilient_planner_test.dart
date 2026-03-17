import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

class MockLLMClient extends Mock implements LLMClient {}

void main() {
  late MockLLMClient mockLLM;
  late ActionRegistry registry;

  setUp(() {
    mockLLM = MockLLMClient();
    registry = ActionRegistry();
    registry.register('tap', (_) async {});
  });

  group('Planner with RetryExecutor', () {
    test('retries LLM call on failure', () async {
      int callCount = 0;

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) throw Exception('LLM timeout');
        return [const ActionDescriptor(actionName: 'tap', args: {'id': '1'})];
      });

      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
        retryExecutor: const RetryExecutor(
          maxAttempts: 3,
          initialDelay: Duration.zero,
        ),
      );

      const uiState = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      final actions = await planner.plan(uiState: uiState, task: 'Tap OK');

      expect(actions, hasLength(1));
      expect(callCount, 3);
    });

    test('throws after retries exhausted', () async {
      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenThrow(Exception('LLM down'));

      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
        retryExecutor: const RetryExecutor(
          maxAttempts: 2,
          initialDelay: Duration.zero,
        ),
      );

      const uiState = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      expect(
        () => planner.plan(uiState: uiState, task: 'Tap OK'),
        throwsException,
      );
    });

    test('works without retryExecutor (no retry)', () async {
      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async => []);

      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
      );

      const uiState = WidgetDescriptor(id: '1', role: 'generic', label: 'Root');
      final actions = await planner.plan(uiState: uiState, task: 'Nothing');
      expect(actions, isEmpty);
    });
  });
}
