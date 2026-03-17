import '../semantic/semantic_tree_walker.dart';
import '../planner/planner.dart';
import '../executor/executor.dart';
import '../verifier/verifier.dart';
import '../privacy/sensitive_data_masker.dart';
import 'agent_callbacks.dart';
import 'consent_handler.dart';
import 'agent_state.dart';
import 'agent_config.dart';

/// Main orchestrator for the Flutter Agent framework.
///
/// [AgentCore] runs the perceive→plan→execute→verify loop:
///
/// 1. **Perceive**: Capture the current UI via [SemanticTreeWalker]
/// 2. **Plan**: Send UI state + task to [Planner] (which calls the LLM)
/// 3. **Execute**: Run LLM-returned actions via [Executor]
/// 4. **Verify**: Check UI changes via [Verifier]
///
/// ```dart
/// final agent = AgentCore(
///   config: AgentConfig(maxSteps: 10),
///   treeWalker: SemanticTreeWalker(),
///   planner: planner,
///   executor: executor,
///   verifier: verifier,
/// );
/// await agent.run('Fill in the form and tap Submit');
/// ```
class AgentCore {
  final AgentConfig config;
  final SemanticTreeWalker _treeWalker;
  final Planner _planner;
  final Executor _executor;
  final Verifier _verifier;
  final SensitiveDataMasker? _sensitiveDataMasker;
  final AgentCallbacks? _callbacks;
  final ConsentHandler? _consentHandler;
  final AgentState _state = AgentState();

  AgentCore({
    required this.config,
    required SemanticTreeWalker treeWalker,
    required Planner planner,
    required Executor executor,
    required Verifier verifier,
    SensitiveDataMasker? sensitiveDataMasker,
    AgentCallbacks? callbacks,
    ConsentHandler? consentHandler,
  })  : _treeWalker = treeWalker,
        _planner = planner,
        _executor = executor,
        _verifier = verifier,
        _sensitiveDataMasker = sensitiveDataMasker,
        _callbacks = callbacks,
        _consentHandler = consentHandler;

  /// Read-only access to the agent's current state.
  AgentState get state => _state;

  /// Run the agent loop for the given [task].
  ///
  /// The loop continues until:
  /// - The LLM returns no actions (task considered complete)
  /// - [AgentConfig.maxSteps] is reached
  /// - An unrecoverable error occurs
  /// - [stop] is called
  Future<void> run(String task) async {
    _state.status = AgentStatus.running;
    _state.stepCount = 0;
    _state.lastError = null;

    int unchangedCount = 0;

    try {
      for (var i = 0; i < config.maxSteps; i++) {
        if (_state.status != AgentStatus.running) break;

        if (config.debugMode) {
          print('[AgentCore] Step ${i + 1}/${config.maxSteps}');
        }

        _callbacks?.onStepStart?.call(i + 1, config.maxSteps);

        // 1. Perceive — capture current UI state
        var uiState = _treeWalker.capture();
        if (uiState == null) {
          _state.lastError = 'Failed to capture semantics tree. '
              'Ensure SemanticsBinding.ensureSemantics() has been called.';
          _state.status = AgentStatus.error;
          break;
        }

        // Apply data masking if enabled
        if (config.enableDataMasking && _sensitiveDataMasker != null) {
          uiState = _sensitiveDataMasker.mask(uiState);
        }

        // 2. Plan — ask LLM what to do
        final actions = await _planner.plan(uiState: uiState, task: task);
        if (actions.isEmpty) {
          if (config.debugMode) {
            print('[AgentCore] LLM returned no actions — task complete.');
          }
          _state.status = AgentStatus.completed;
          break;
        }

        if (config.debugMode) {
          print('[AgentCore] LLM returned ${actions.length} action(s): '
              '${actions.map((a) => a.actionName).join(", ")}');
        }

        // 2.5. Consent — ask user before executing
        if (_consentHandler != null) {
          final approved = await _consentHandler.requestConsent(actions);
          if (!approved) {
            if (config.debugMode) {
              print('[AgentCore] User denied consent — skipping actions.');
            }
            _state.status = AgentStatus.completed;
            break;
          }
        }

        // 3. Execute — run the actions
        await _executor.executeAll(actions);

        // 4. Verify — did the UI change?
        final postState = _treeWalker.capture();
        final verification = _verifier.verify(
          before: uiState,
          after: postState,
        );

        _state.stepCount++;

        if (verification == VerificationResult.unchanged) {
          unchangedCount++;
          _state.lastError =
              'UI unchanged after actions (attempt $unchangedCount/${config.maxRetries})';
          if (config.debugMode) {
            print('[AgentCore] ${_state.lastError}');
          }
          if (unchangedCount >= config.maxRetries) {
            _state.status = AgentStatus.error;
            break;
          }
        } else {
          unchangedCount = 0; // reset on successful change
        }

        // Delay between steps to let UI settle
        await Future.delayed(config.stepDelay);
      }

      // If we exhausted steps without completion or error
      if (_state.status == AgentStatus.running) {
        _state.status = AgentStatus.completed;
      }
      _callbacks?.onComplete?.call(_state.status.name);
    } catch (e) {
      _state.lastError = e.toString();
      _state.status = AgentStatus.error;
      _callbacks?.onError?.call(e);
      _callbacks?.onComplete?.call('error');
      if (config.debugMode) {
        print('[AgentCore] Error: $e');
      }
    }
  }

  /// Stop the agent loop after the current step completes.
  void stop() {
    _state.status = AgentStatus.paused;
  }
}
