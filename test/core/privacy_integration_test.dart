import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_agent/flutter_agent.dart';

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

  const rawTree = WidgetDescriptor(
    id: '1', role: 'generic', label: 'Root',
    children: [
      WidgetDescriptor(
        id: '2', role: 'textField', label: 'user@email.com',
        value: '4111-1111-1111-1111',
      ),
    ],
  );

  setUp(() {
    treeWalker = MockTreeWalker();
    planner = MockPlanner();
    executor = MockExecutor();
    verifier = MockVerifier();
  });

  group('Privacy-aware AgentCore', () {
    test('masks sensitive data before planning when enableDataMasking=true', () async {
      final masker = SensitiveDataMasker();
      final config = const AgentConfig(
        maxSteps: 1,
        enableDataMasking: true,
      );

      final agent = AgentCore(
        config: config,
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        sensitiveDataMasker: masker,
      );

      when(() => treeWalker.capture()).thenReturn(rawTree);
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => []);

      await agent.run('Test');

      // Verify that planner received a masked tree (email replaced)
      final captured = verify(() => planner.plan(
            uiState: captureAny(named: 'uiState'),
            task: any(named: 'task'),
          )).captured;

      final passedTree = captured.first as WidgetDescriptor;
      expect(passedTree.children.first.label, isNot(contains('@')));
      expect(passedTree.children.first.value, isNot(contains('4111')));
    });

    test('does NOT mask when enableDataMasking=false', () async {
      final config = const AgentConfig(
        maxSteps: 1,
        enableDataMasking: false,
      );

      final agent = AgentCore(
        config: config,
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
      );

      when(() => treeWalker.capture()).thenReturn(rawTree);
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => []);

      await agent.run('Test');

      final captured = verify(() => planner.plan(
            uiState: captureAny(named: 'uiState'),
            task: any(named: 'task'),
          )).captured;

      final passedTree = captured.first as WidgetDescriptor;
      expect(passedTree.children.first.label, contains('@'));
    });
  });
}
