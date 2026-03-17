import 'package:flutter/material.dart';
import '../agent_demo_base.dart';

/// Form/Settings Demo — tests `setText` + `tap` (switch, submit) actions.
///
/// Agent task: Fill in form fields, toggle switch, submit.
class FormDemo extends StatefulWidget {
  const FormDemo({super.key});

  @override
  State<FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<FormDemo> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _darkMode = false;
  bool _notifications = true;
  bool _submitted = false;
  String _submittedSummary = '';

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;

    setState(() {
      _submitted = true;
      _submittedSummary =
          'Name: $name\nEmail: $email\nDark Mode: ${_darkMode ? "ON" : "OFF"}\nNotifications: ${_notifications ? "ON" : "OFF"}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AgentDemoScaffold(
      title: 'Form Demo',
      agentTask:
          "Fill in the Name field with 'John Doe', fill in the Email field with 'john@example.com', "
          "turn on the Dark Mode switch, then tap the Submit button.",
      maxSteps: 20,
      body: _submitted ? _buildResult() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Name field
          Semantics(
            label: 'Name',
            textField: true,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email field
          Semantics(
            label: 'Email',
            textField: true,
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Dark Mode toggle
          Semantics(
            label: 'Dark Mode',
            toggled: _darkMode,
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ),

          // Notifications toggle
          Semantics(
            label: 'Notifications',
            toggled: _notifications,
            child: SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          Semantics(
            label: 'Submit settings',
            button: true,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Semantics(
              label: 'Submission result',
              value: 'Settings saved successfully',
              child: Text(
                'Settings Saved!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Submitted values',
              value: _submittedSummary,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _submittedSummary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => setState(() {
                _submitted = false;
                _nameController.clear();
                _emailController.clear();
                _darkMode = false;
                _notifications = true;
              }),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
