import 'package:flutter/material.dart' hide ActionDispatcher;
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

/// Example app demonstrating ai_flutter_agent integration.
///
/// This counter app registers tap/increment actions and shows
/// how to wire up AgentCore with a simple UI.
void main() {
  runApp(
    const AgentOverlayWidget(
      enabled: true,
      child: CounterApp(),
    ),
  );
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Agent Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;
  String _agentStatus = 'Idle';

  void _increment() => setState(() => _counter++);
  void _decrement() => setState(() => _counter--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Counter Value',
              value: '$_counter',
              child: Text(
                '$_counter',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Decrement',
                  button: true,
                  child: FloatingActionButton(
                    heroTag: 'decrement',
                    onPressed: _decrement,
                    child: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: 'Increment',
                  button: true,
                  child: FloatingActionButton(
                    heroTag: 'increment',
                    onPressed: _increment,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Agent Status: $_agentStatus', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                print('--- BUTTON TAPPED ---');
                _runAgent(context);
              },
              child: const Text('Run Agent: Increment 3 times'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAgent(BuildContext context) async {
    print('--- _runAgent START ---');
    // 1. Set up action registry with built-in actions
    final registry = ActionRegistry();
    BuiltInActions.registerDefaults(registry);

    // 2. Create the real LLM client using the user-provided local server URL
    // (Using 127.0.0.1 via adb reverse tcp:1234 tcp:1234 since it's a physical device)
    final client = OpenAILLMClient(
      apiKey: 'test-key',
      baseUrl: 'http://127.0.0.1:1234/v1',
      model: 'local-model', // Model name doesn't usually matter for LM Studio 
    );

    // 3. Create the agent components and the agent itself
    final treeWalker = SemanticTreeWalker();
    final auditLog = AuditLog();
    final dispatcher = ActionDispatcher(registry: registry);

    // 3. Create the planner to translate UI states into LLM prompts
    final history = ConversationHistory(maxTurns: 10);
    final planner = Planner(
      llmClient: client, 
      actionRegistry: registry,
      conversationHistory: history,
    );

    final agent = AgentCore(
      treeWalker: treeWalker,
      planner: planner,
      executor: Executor(actionRegistry: registry, auditLog: auditLog, actionDispatcher: dispatcher),
      verifier: Verifier(treeWalker: treeWalker),
      config: const AgentConfig(
        maxSteps: 6,
        stepDelay: Duration(seconds: 1),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting Agent: Please observe the UI...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      setState(() => _agentStatus = 'Running...');
      // 4. Run the autonomous loop
      await agent.run('Please click the Increment button 3 times exactly.');
      
      if (mounted) setState(() => _agentStatus = 'Success!');
    } catch (e) {
      if (mounted) setState(() => _agentStatus = 'Error: $e');
    }
  }
}
