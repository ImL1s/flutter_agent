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
    registry.register('enterText', (_) async {});
  });

  group('Planner with ConversationHistory', () {
    test('passes conversation messages to LLM', () async {
      final history = ConversationHistory();
      history.addUserMessage('Previous instruction');

      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
        conversationHistory: history,
      );

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async => [
            const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          ]);

      const uiState = WidgetDescriptor(
        id: '1', role: 'button', label: 'Submit',
      );
      await planner.plan(uiState: uiState, task: 'Tap Submit');

      final captured = verify(() => mockLLM.requestActions(
            prompt: captureAny(named: 'prompt'),
            toolSchemas: captureAny(named: 'toolSchemas'),
            messages: captureAny(named: 'messages'),
          )).captured;

      final messages = captured[2] as List<Map<String, dynamic>>?;
      expect(messages, isNotNull);
      expect(messages!.any((m) => m['content'] == 'Previous instruction'), isTrue);
    });

    test('records assistant tool calls to history after plan()', () async {
      final history = ConversationHistory();
      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
        conversationHistory: history,
      );

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async => [
            const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          ]);

      const uiState = WidgetDescriptor(
        id: '1', role: 'button', label: 'Submit',
      );
      await planner.plan(uiState: uiState, task: 'Tap Submit');

      // History should have: user message (prompt) + assistant tool calls
      final messages = history.toMessages();
      expect(messages.length, greaterThanOrEqualTo(2));
      expect(messages.last['role'], 'assistant');
    });

    test('works without conversationHistory (backward compatible)', () async {
      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
      );

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async => []);

      const uiState = WidgetDescriptor(
        id: '1', role: 'generic', label: 'Root',
      );
      final actions = await planner.plan(uiState: uiState, task: 'Do nothing');
      expect(actions, isEmpty);
    });
  });
}
