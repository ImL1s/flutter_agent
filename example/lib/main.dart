import 'package:flutter/material.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

/// Example app demonstrating flutter_agent integration.
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
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => _runAgent(context),
              child: const Text('Run Agent: Increment 3 times'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAgent(BuildContext context) async {
    // 1. Set up action registry with built-in actions
    final registry = ActionRegistry();
    BuiltInActions.registerDefaults(registry);

    // Also register a custom increment action
    registry.register('increment', (_) async => _increment(),
        description: 'Increment the counter');

    // 2. Create agent components
    // NOTE: In production, use a real LLM client like OpenAILLMClient.
    // This demo shows the wiring only.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Agent wiring demo — in production, connect a real LLM client.\n'
          'See README.md for full usage.',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    // Demo: just execute the increment action 3 times directly
    for (var i = 0; i < 3; i++) {
      await registry.execute('increment', {});
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}
