import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_flutter_agent/src/planner/planner.dart';
import 'package:ai_flutter_agent/src/llm/llm_client.dart';
import 'package:ai_flutter_agent/src/action/action_registry.dart';
import 'package:ai_flutter_agent/src/models/widget_descriptor.dart';
import 'package:ai_flutter_agent/src/models/action_descriptor.dart';

class MockLLMClient extends Mock implements LLMClient {}

void main() {
  late MockLLMClient mockLLM;
  late ActionRegistry registry;
  late Planner planner;

  setUp(() {
    mockLLM = MockLLMClient();
    registry = ActionRegistry();
    registry.register('tap', (_) async {});
    registry.register('enterText', (_) async {});
    planner = Planner(llmClient: mockLLM, actionRegistry: registry);
  });

  group('Planner', () {
    test('buildPrompt includes UI state and task', () {
      const uiState = WidgetDescriptor(
        id: '1',
        role: 'button',
        label: 'Submit',
        actions: ['tap'],
      );
      final prompt = planner.buildPrompt(uiState, 'Tap Submit');
      expect(prompt, contains('Submit'));
      expect(prompt, contains('button'));
      expect(prompt, contains('Tap Submit'));
      expect(prompt, contains('tap'));
      expect(prompt, contains('enterText'));
    });

    test('buildPrompt formats nested tree', () {
      const child = WidgetDescriptor(
        id: '2',
        role: 'textField',
        label: 'Name',
        value: 'John',
      );
      const root = WidgetDescriptor(
        id: '1',
        role: 'generic',
        label: 'Form',
        children: [child],
      );
      final prompt = planner.buildPrompt(root, 'Fill form');
      expect(prompt, contains('Name'));
      expect(prompt, contains('John'));
      expect(prompt, contains('textField'));
    });

    test('plan sends prompt to LLM and returns actions', () async {
      const uiState = WidgetDescriptor(
        id: '1',
        role: 'button',
        label: 'Submit',
      );

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
          )).thenAnswer((_) async => [
            const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          ]);

      final actions = await planner.plan(
        uiState: uiState,
        task: 'Tap Submit',
      );

      expect(actions, hasLength(1));
      expect(actions.first.actionName, 'tap');

      // Verify LLM was called with tool schemas
      final captured = verify(() => mockLLM.requestActions(
            prompt: captureAny(named: 'prompt'),
            toolSchemas: captureAny(named: 'toolSchemas'),
          )).captured;
      final schemas = captured[1] as List;
      expect(schemas, hasLength(2)); // tap + enterText
    });

    test('plan returns empty when LLM returns no actions', () async {
      const uiState = WidgetDescriptor(
        id: '1',
        role: 'generic',
        label: 'Empty',
      );

      when(() => mockLLM.requestActions(
            prompt: any(named: 'prompt'),
            toolSchemas: any(named: 'toolSchemas'),
          )).thenAnswer((_) async => []);

      final actions = await planner.plan(
        uiState: uiState,
        task: 'Do nothing',
      );

      expect(actions, isEmpty);
    });
  });
}
