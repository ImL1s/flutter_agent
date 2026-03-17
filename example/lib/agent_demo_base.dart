import 'package:flutter/material.dart' hide ActionDispatcher;
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

/// Shared agent runner helper for all demo pages.
///
/// Encapsulates the boilerplate of setting up ActionRegistry, LLM client,
/// Planner, Executor, Verifier, and AgentCore.
class AgentRunner {
  final String baseUrl;
  final String model;
  final int maxSteps;
  final Duration stepDelay;

  AgentRunner({
    this.baseUrl = 'http://192.168.1.128:1234/v1',
    this.model = 'local-model',
    this.maxSteps = 10,
    this.stepDelay = const Duration(seconds: 1),
  });

  /// Run the agent with the given [task] prompt.
  ///
  /// Returns the final [AgentState] containing status and error info.
  Future<AgentState> run(String task) async {
    final registry = ActionRegistry();
    final semanticsExecutor = SemanticsActionExecutor();
    BuiltInActions.registerDefaults(
      registry,
      performAction: (nodeId, action, {Object? actionArgs}) async {
        await semanticsExecutor.performAction(nodeId, action, actionArgs: actionArgs);
      },
    );

    final llmClient = OpenAILLMClient(
      apiKey: 'not-needed-for-local',
      baseUrl: baseUrl,
      model: model,
    );

    final treeWalker = SemanticTreeWalker();
    final auditLog = AuditLog();
    final dispatcher = ActionDispatcher(registry: registry);
    final history = ConversationHistory(maxTurns: 20);
    final planner = Planner(
      llmClient: llmClient,
      actionRegistry: registry,
      conversationHistory: history,
    );

    final agent = AgentCore(
      treeWalker: treeWalker,
      planner: planner,
      executor: Executor(
        actionRegistry: registry,
        auditLog: auditLog,
        actionDispatcher: dispatcher,
      ),
      verifier: Verifier(treeWalker: treeWalker),
      config: AgentConfig(
        maxSteps: maxSteps,
        stepDelay: stepDelay,
        debugMode: true,
      ),
    );

    await agent.run(task);
    return agent.state;
  }
}

/// A reusable widget that wraps a demo page with Agent status and Run button.
class AgentDemoScaffold extends StatefulWidget {
  final String title;
  final String agentTask;
  final Widget body;
  final int maxSteps;

  const AgentDemoScaffold({
    super.key,
    required this.title,
    required this.agentTask,
    required this.body,
    this.maxSteps = 10,
  });

  @override
  State<AgentDemoScaffold> createState() => _AgentDemoScaffoldState();
}

class _AgentDemoScaffoldState extends State<AgentDemoScaffold> {
  String _status = 'Idle';
  bool _running = false;

  Future<void> _runAgent() async {
    setState(() {
      _status = 'Running...';
      _running = true;
    });

    try {
      final runner = AgentRunner(maxSteps: widget.maxSteps);
      final state = await runner.run(widget.agentTask);

      if (mounted) {
        setState(() {
          _running = false;
          if (state.status == AgentStatus.error) {
            _status = 'Error: ${state.lastError}';
          } else {
            _status = 'Success!';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = _status.startsWith('Error');
    final isSuccess = _status == 'Success!';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(child: widget.body),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agent: $_status',
                  style: TextStyle(
                    color: isError
                        ? Colors.red
                        : isSuccess
                            ? Colors.green
                            : null,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runAgent,
                    icon: _running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.smart_toy),
                    label: Text(_running ? 'Agent Running...' : 'Run Agent'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
