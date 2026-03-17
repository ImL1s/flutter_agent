import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:flutter_agent/src/core/agent_core.dart';
import 'package:flutter_agent/src/core/agent_config.dart';
import 'package:flutter_agent/src/core/agent_state.dart';
import 'package:flutter_agent/src/semantic/semantic_tree_walker.dart';
import 'package:flutter_agent/src/planner/planner.dart';
import 'package:flutter_agent/src/executor/executor.dart';
import 'package:flutter_agent/src/verifier/verifier.dart';
import 'package:flutter_agent/src/models/widget_descriptor.dart';
import 'package:flutter_agent/src/models/action_descriptor.dart';

class MockSemanticTreeWalker extends Mock implements SemanticTreeWalker {}
class MockPlanner extends Mock implements Planner {}
class MockExecutor extends Mock implements Executor {}
class MockVerifier extends Mock implements Verifier {}

void main() {
  late MockSemanticTreeWalker mockWalker;
  late MockPlanner mockPlanner;
  late MockExecutor mockExecutor;
  late MockVerifier mockVerifier;
  late AgentCore agent;

  setUpAll(() {
    registerFallbackValue(const WidgetDescriptor(id: '0', role: '', label: ''));
    registerFallbackValue(<ActionDescriptor>[]);
  });

  setUp(() {
    mockWalker = MockSemanticTreeWalker();
    mockPlanner = MockPlanner();
    mockExecutor = MockExecutor();
    mockVerifier = MockVerifier();
    agent = AgentCore(
      config: const AgentConfig(
        maxSteps: 5,
        maxRetries: 2,
        stepDelay: Duration.zero,
      ),
      treeWalker: mockWalker,
      planner: mockPlanner,
      executor: mockExecutor,
      verifier: mockVerifier,
    );
  });

  group('AgentCore', () {
    test('starts in idle state', () {
      expect(agent.state.status, AgentStatus.idle);
      expect(agent.state.stepCount, 0);
    });

    test('completes when LLM returns no actions', () async {
      const uiState = WidgetDescriptor(
        id: '1', role: 'generic', label: 'Root',
      );

      when(() => mockWalker.capture()).thenReturn(uiState);
      when(() => mockPlanner.plan(
        uiState: any(named: 'uiState'),
        task: any(named: 'task'),
      )).thenAnswer((_) async => []); // no actions = done

      await agent.run('test task');

      expect(agent.state.status, AgentStatus.completed);
    });

    test('errors when semantics tree is null', () async {
      when(() => mockWalker.capture()).thenReturn(null);

      await agent.run('test task');

      expect(agent.state.status, AgentStatus.error);
      expect(agent.state.lastError, contains('semantics'));
    });

    test('executes actions and advances step count', () async {
      const uiState1 = WidgetDescriptor(
        id: '1', role: 'button', label: 'Before',
      );
      const uiState2 = WidgetDescriptor(
        id: '1', role: 'button', label: 'After',
      );

      var callCount = 0;
      when(() => mockWalker.capture()).thenAnswer((_) {
        callCount++;
        return callCount <= 2 ? uiState1 : uiState2;
      });

      when(() => mockPlanner.plan(
        uiState: any(named: 'uiState'),
        task: any(named: 'task'),
      )).thenAnswer((invocation) async {
        // Return action on first call, empty on second
        if (callCount <= 2) {
          return [const ActionDescriptor(actionName: 'tap', args: {'id': '1'})];
        }
        return [];
      });

      when(() => mockExecutor.executeAll(any()))
          .thenAnswer((_) async => [
                ExecutionResult(
                  action: const ActionDescriptor(actionName: 'tap'),
                  success: true,
                ),
              ]);

      when(() => mockVerifier.verify(
        before: any(named: 'before'),
        after: any(named: 'after'),
      )).thenReturn(VerificationResult.changed);

      await agent.run('Tap the button');

      expect(agent.state.stepCount, greaterThan(0));
    });

    test('stop pauses the agent', () async {
      const uiState = WidgetDescriptor(
        id: '1', role: 'generic', label: 'Root',
      );

      when(() => mockWalker.capture()).thenReturn(uiState);
      when(() => mockPlanner.plan(
        uiState: any(named: 'uiState'),
        task: any(named: 'task'),
      )).thenAnswer((_) async {
        agent.stop(); // stop mid-loop
        return [const ActionDescriptor(actionName: 'tap', args: {})];
      });
      when(() => mockExecutor.executeAll(any()))
          .thenAnswer((_) async => [
                ExecutionResult(
                  action: const ActionDescriptor(actionName: 'tap'),
                  success: true,
                ),
              ]);
      when(() => mockVerifier.verify(
        before: any(named: 'before'),
        after: any(named: 'after'),
      )).thenReturn(VerificationResult.changed);

      await agent.run('test');

      expect(agent.state.status, AgentStatus.paused);
    });

    test('errors after maxRetries unchanged states', () async {
      const uiState = WidgetDescriptor(
        id: '1', role: 'button', label: 'Same',
      );

      when(() => mockWalker.capture()).thenReturn(uiState);
      when(() => mockPlanner.plan(
        uiState: any(named: 'uiState'),
        task: any(named: 'task'),
      )).thenAnswer((_) async => [
        const ActionDescriptor(actionName: 'tap', args: {}),
      ]);
      when(() => mockExecutor.executeAll(any()))
          .thenAnswer((_) async => [
                ExecutionResult(
                  action: const ActionDescriptor(actionName: 'tap'),
                  success: true,
                ),
              ]);
      when(() => mockVerifier.verify(
        before: any(named: 'before'),
        after: any(named: 'after'),
      )).thenReturn(VerificationResult.unchanged);

      await agent.run('test');

      expect(agent.state.status, AgentStatus.error);
      expect(agent.state.lastError, contains('unchanged'));
    });
  });
}
