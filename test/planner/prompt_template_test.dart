import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_agent/flutter_agent.dart';

class MockLLMClient extends Mock implements LLMClient {}

void main() {
  const uiState = WidgetDescriptor(
    id: '1',
    role: 'button',
    label: 'Submit',
    actions: ['tap'],
  );

  group('DefaultPromptTemplate', () {
    test('formats prompt with UI state, task, and actions', () {
      const template = DefaultPromptTemplate();
      final result = template.format(
        uiState: uiState,
        task: 'Tap the Submit button',
        actionNames: ['tap', 'scroll'],
      );

      expect(result, contains('Submit'));
      expect(result, contains('Tap the Submit button'));
      expect(result, contains('tap, scroll'));
      expect(result, contains('id=1'));
    });

    test('includes child nodes in tree', () {
      const parent = WidgetDescriptor(
        id: '0',
        role: 'generic',
        label: 'Root',
        children: [uiState],
      );
      const template = DefaultPromptTemplate();
      final result = template.format(
        uiState: parent,
        task: 'Test',
        actionNames: ['tap'],
      );

      expect(result, contains('Root'));
      expect(result, contains('Submit'));
    });
  });

  group('CustomPromptTemplate', () {
    test('substitutes {ui}, {task}, {actions} placeholders', () {
      const template = CustomPromptTemplate(
        template: 'UI:\n{ui}\n\nJob: {task}\nTools: {actions}',
      );
      final result = template.format(
        uiState: uiState,
        task: 'Click Submit',
        actionNames: ['tap'],
      );

      expect(result, contains('UI:'));
      expect(result, contains('Job: Click Submit'));
      expect(result, contains('Tools: tap'));
      expect(result, contains('Submit'));
    });
  });

  group('Planner with PromptTemplate', () {
    test('uses custom template when provided', () async {
      final mockLLM = MockLLMClient();
      final registry = ActionRegistry();
      registry.register('tap', (_) async {});

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).thenAnswer((_) async => []);

      final planner = Planner(
        llmClient: mockLLM,
        actionRegistry: registry,
        promptTemplate: const CustomPromptTemplate(
          template: 'CUSTOM: {task} | {actions}',
        ),
      );

      await planner.plan(uiState: uiState, task: 'do it');

      final captured = verify(() => mockLLM.requestActions(
            prompt: captureAny(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
            messages: any(named: 'messages'),
          )).captured.first as String;

      expect(captured, startsWith('CUSTOM:'));
      expect(captured, contains('do it'));
    });
  });
}
