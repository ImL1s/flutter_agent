import 'package:flutter/material.dart';
import '../agent_demo_base.dart';

/// Counter Demo — tests basic `tap` action.
///
/// Agent task: Tap the Increment button 3 times.
class CounterDemo extends StatefulWidget {
  const CounterDemo({super.key});

  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);
  void _decrement() => setState(() => _counter--);

  @override
  Widget build(BuildContext context) {
    return AgentDemoScaffold(
      title: 'Counter Demo',
      agentTask: 'Please click the Increment button 3 times exactly.',
      maxSteps: 6,
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
                    heroTag: 'dec',
                    onPressed: _decrement,
                    child: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: 'Increment',
                  button: true,
                  child: FloatingActionButton(
                    heroTag: 'inc',
                    onPressed: _increment,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
