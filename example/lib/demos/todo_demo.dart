import 'package:flutter/material.dart';
import '../agent_demo_base.dart';

/// Todo List Demo — tests `tap` + `setText` actions.
///
/// Agent task: Add two todos and check one off.
class TodoDemo extends StatefulWidget {
  const TodoDemo({super.key});

  @override
  State<TodoDemo> createState() => _TodoDemoState();
}

class _TodoDemoState extends State<TodoDemo> {
  final List<_TodoItem> _todos = [
    _TodoItem('Review Flutter Agent code', false),
  ];
  final _controller = TextEditingController();

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _todos.add(_TodoItem(text, false));
        _controller.clear();
      });
    }
  }

  void _toggleTodo(int index) {
    setState(() => _todos[index].done = !_todos[index].done);
  }

  void _deleteTodo(int index) {
    setState(() => _todos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return AgentDemoScaffold(
      title: 'Todo Demo',
      agentTask:
          "Add a todo called 'Buy groceries' by typing it in the text field and tapping Add. "
          "Then add another todo called 'Walk the dog'. "
          "Then tap the checkbox next to 'Buy groceries' to mark it as done.",
      maxSteps: 12,
      body: Column(
        children: [
          // Input row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'New todo text field',
                    textField: true,
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter a new todo...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Add todo',
                  button: true,
                  child: FilledButton(
                    onPressed: _addTodo,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Todo list
          Expanded(
            child: _todos.isEmpty
                ? const Center(child: Text('No todos yet'))
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return Semantics(
                        label: todo.title,
                        child: ListTile(
                          leading: Semantics(
                            label: 'Toggle ${todo.title}',
                            checked: todo.done,
                            child: Checkbox(
                              value: todo.done,
                              onChanged: (_) => _toggleTodo(index),
                            ),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: Semantics(
                            label: 'Delete ${todo.title}',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteTodo(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Semantics(
              label: 'Todo count',
              value: '${_todos.where((t) => t.done).length}/${_todos.length} completed',
              child: Text(
                '${_todos.where((t) => t.done).length}/${_todos.length} completed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItem {
  final String title;
  bool done;
  _TodoItem(this.title, this.done);
}
