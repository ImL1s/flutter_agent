import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:flutter_agent/flutter_agent.dart';

class MockTreeWalker extends Mock implements SemanticTreeWalker {}
class MockPlanner extends Mock implements Planner {}
class MockExecutor extends Mock implements Executor {}
class MockVerifier extends Mock implements Verifier {}

/// Tracks consent calls for testing.
class TrackingConsentHandler implements ConsentHandler {
  final bool shouldApprove;
  final calls = <List<ActionDescriptor>>[];

  TrackingConsentHandler({this.shouldApprove = true});

  @override
  Future<bool> requestConsent(List<ActionDescriptor> actions) async {
    calls.add(actions);
    return shouldApprove;
  }
}

void main() {
  late MockTreeWalker treeWalker;
  late MockPlanner planner;
  late MockExecutor executor;
  late MockVerifier verifier;

  setUpAll(() {
    registerFallbackValue(const WidgetDescriptor(id: '', role: '', label: ''));
    registerFallbackValue(<ActionDescriptor>[]);
  });

  setUp(() {
    treeWalker = MockTreeWalker();
    planner = MockPlanner();
    executor = MockExecutor();
    verifier = MockVerifier();

    when(() => treeWalker.capture()).thenReturn(
      const WidgetDescriptor(id: '1', role: 'generic', label: 'Root'),
    );
  });

  group('ConsentHandler', () {
    test('AutoApproveConsentHandler always returns true', () async {
      const handler = AutoApproveConsentHandler();
      expect(await handler.requestConsent([]), isTrue);
    });

    test('AutoDenyConsentHandler always returns false', () async {
      const handler = AutoDenyConsentHandler();
      expect(await handler.requestConsent([]), isFalse);
    });
  });

  group('AgentCore with ConsentHandler', () {
    test('skips execution when consent denied', () async {
      final consent = TrackingConsentHandler(shouldApprove: false);

      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        consentHandler: consent,
      );

      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => [
            const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
          ]);

      await agent.run('Test');

      // Consent was asked
      expect(consent.calls, hasLength(1));
      // Executor was NOT called because consent was denied
      verifyNever(() => executor.executeAll(any()));
    });

    test('executes when consent approved', () async {
      final consent = TrackingConsentHandler(shouldApprove: true);

      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
        consentHandler: consent,
      );

      final actions = [
        const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
      ];
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => actions);
      when(() => executor.executeAll(any())).thenAnswer((_) async => []);
      when(() => verifier.verify(
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenReturn(VerificationResult.changed);

      await agent.run('Test');

      expect(consent.calls, hasLength(1));
      verify(() => executor.executeAll(any())).called(1);
    });

    test('works without consentHandler (no gate)', () async {
      final agent = AgentCore(
        config: const AgentConfig(maxSteps: 1),
        treeWalker: treeWalker,
        planner: planner,
        executor: executor,
        verifier: verifier,
      );

      final actions = [
        const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
      ];
      when(() => planner.plan(
            uiState: any(named: 'uiState'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => actions);
      when(() => executor.executeAll(any())).thenAnswer((_) async => []);
      when(() => verifier.verify(
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenReturn(VerificationResult.changed);

      await agent.run('Test');

      // Runs normally without consent handler
      verify(() => executor.executeAll(any())).called(1);
    });
  });
}
