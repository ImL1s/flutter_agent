import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_agent/flutter_agent.dart';

/// Example app demonstrating flutter_agent integration.
///
/// This app creates a simple form UI with semantic annotations,
/// registers actions in the ActionRegistry, and shows how to
/// configure and run the AgentCore.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable semantics so the SemanticTreeWalker can capture the tree.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const FlutterAgentExampleApp());
}

class FlutterAgentExampleApp extends StatelessWidget {
  const FlutterAgentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Agent Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleFormPage(),
    );
  }
}

class ExampleFormPage extends StatefulWidget {
  const ExampleFormPage({super.key});

  @override
  State<ExampleFormPage> createState() => _ExampleFormPageState();
}

class _ExampleFormPageState extends State<ExampleFormPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _statusMessage = 'Ready';
  bool _isAgentRunning = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          label: 'Flutter Agent Demo',
          child: const Text('Flutter Agent Demo'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field with semantics
            Semantics(
              textField: true,
              label: 'Name',
              hint: 'Enter your name',
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email field with semantics
            Semantics(
              textField: true,
              label: 'Email',
              hint: 'Enter your email',
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button with semantics
            Semantics(
              button: true,
              label: 'Submit',
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _statusMessage =
                        'Submitted: ${_nameController.text}, ${_emailController.text}';
                  });
                },
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(height: 16),

            // Status display
            Semantics(
              label: 'Status',
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Spacer(),

            // Agent control button
            Semantics(
              button: true,
              label: _isAgentRunning ? 'Agent Running...' : 'Run Agent',
              child: ElevatedButton.icon(
                onPressed: _isAgentRunning ? null : _runAgentDemo,
                icon: Icon(
                    _isAgentRunning ? Icons.hourglass_top : Icons.smart_toy),
                label: Text(
                    _isAgentRunning ? 'Agent Running...' : 'Run Agent Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAgentDemo() async {
    setState(() {
      _isAgentRunning = true;
      _statusMessage = 'Agent is analyzing the UI...';
    });

    // 1. Set up the action registry
    final registry = ActionRegistry();
    registry.register('tap', (args) async {
      print('[Agent] Tapping node ${args['id']}');
      // In a real app, this would use SemanticsOwner.performAction
    });
    registry.register('enterText', (args) async {
      print('[Agent] Entering text "${args['text']}" in node ${args['id']}');
    });

    // 2. Create components
    final treeWalker = SemanticTreeWalker();
    final auditLog = AuditLog();

    // NOTE: To actually run the agent, you'd need a real LLM client:
    // final llmClient = OpenAILLMClient(apiKey: 'your-key');
    //
    // For this demo, we just show the tree capture:
    final uiTree = treeWalker.capture();

    setState(() {
      if (uiTree != null) {
        _statusMessage = 'Captured UI tree with root: '
            '${uiTree.role} "${uiTree.label}" '
            '(${uiTree.children.length} children)';
      } else {
        _statusMessage = 'Could not capture semantics tree. '
            'Make sure semantics are enabled.';
      }
      _isAgentRunning = false;
    });

    // Print the tree for debugging
    if (uiTree != null) {
      _printTree(uiTree, indent: 0);
    }

    // Print audit log
    print('[AuditLog] ${auditLog.length} entries recorded');
  }

  void _printTree(WidgetDescriptor node, {required int indent}) {
    final prefix = '  ' * indent;
    print('$prefix[${node.role}] id=${node.id} '
        'label="${node.label}" '
        '${node.value.isNotEmpty ? 'value="${node.value}" ' : ''}'
        '${node.actions.isNotEmpty ? 'actions=${node.actions}' : ''}');
    for (final child in node.children) {
      _printTree(child, indent: indent + 1);
    }
  }
}
