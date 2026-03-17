import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

class MockTreeWalker extends Mock implements SemanticTreeWalker {}
class MockPlanner extends Mock implements Planner {}
class MockExecutor extends Mock implements Executor {}
class MockVerifier extends Mock implements Verifier {}

void main() {
  late MockTreeWalker treeWalker;
  late MockPlanner planner;
  late MockExecutor executor;
  late MockVerifier verifier;

  setUpAll(() {
    registerFallbackValue(const WidgetDescriptor(id: '', role: '', label: ''));
  });

  setUp(() {
    treeWalker = MockTreeWalker();
    planner = MockPlanner();
    executor = MockExecutor();
    verifier = MockVerifier();
  });

  group('AgentCallbacks', () {
    test('onStepStart called with step number', () async {
      final stepStarts = <int>[];
      final callbacks = AgentCallbacks(
        onStepStart: (step, max) => stepStarts.add(step),
      );

      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 2),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        callbacks: callbacks,
      );

      when(() => treeWalker.capture()).thenReturn(
        const WidgetDescriptor(id: '1', role: 'generic', label: 'Root'),
      );
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => []);

      await agent.run('Test');

      // Step 1 starts, then LLM returns empty → task complete
      expect(stepStarts, contains(1));
    });

    test('onComplete called with reason', () async {
      String? reason;
      final callbacks = AgentCallbacks(
        onComplete: (r) => reason = r,
      );

      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        callbacks: callbacks,
      );

      when(() => treeWalker.capture()).thenReturn(
        const WidgetDescriptor(id: '1', role: 'generic', label: 'Root'),
      );
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => []);

      await agent.run('Test');
      expect(reason, isNotNull);
    });

    test('onError called when planner throws', () async {
      Object? caughtError;
      final callbacks = AgentCallbacks(
        onError: (e) => caughtError = e,
      );

      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        callbacks: callbacks,
      );

      when(() => treeWalker.capture()).thenReturn(
        const WidgetDescriptor(id: '1', role: 'generic', label: 'Root'),
      );
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenThrow(Exception('LLM down'));

      await agent.run('Test');
      expect(caughtError, isNotNull);
    });

    test('works without callbacks (backward compatible)', () async {
      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
      );

      when(() => treeWalker.capture()).thenReturn(
        const WidgetDescriptor(id: '1', role: 'generic', label: 'Root'),
      );
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => []);

      await agent.run('Test');
      expect(agent.state.status, AgentStatus.completed);
    });
  });
}
