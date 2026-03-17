import 'package:flutter/material.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';
import 'demos/counter_demo.dart';
import 'demos/todo_demo.dart';
import 'demos/chat_demo.dart';
import 'demos/form_demo.dart';
import 'demos/shopping_demo.dart';

/// Demo Hub — entry point for all AI Agent demo scenarios.
void main() {
  runApp(
    const AgentOverlayWidget(
      enabled: true,
      child: DemoApp(),
    ),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Agent Demos',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const DemoHubPage(),
    );
  }
}

class DemoHubPage extends StatelessWidget {
  const DemoHubPage({super.key});

  static const _demos = <_DemoEntry>[
    _DemoEntry(
      title: 'Counter',
      subtitle: 'Tap the + button 3 times',
      icon: Icons.add_circle_outline,
      actions: ['tap'],
      page: CounterDemo(),
    ),
    _DemoEntry(
      title: 'Todo List',
      subtitle: 'Add todos, check them off',
      icon: Icons.checklist,
      actions: ['tap', 'setText'],
      page: TodoDemo(),
    ),
    _DemoEntry(
      title: 'Chat / IM',
      subtitle: 'Type a message and send it',
      icon: Icons.chat_bubble_outline,
      actions: ['setText', 'tap'],
      page: ChatDemo(),
    ),
    _DemoEntry(
      title: 'Form / Settings',
      subtitle: 'Fill fields, toggle switches, submit',
      icon: Icons.settings,
      actions: ['setText', 'tap'],
      page: FormDemo(),
    ),
    _DemoEntry(
      title: 'Shopping',
      subtitle: 'Add items to cart, scroll to find',
      icon: Icons.shopping_cart_outlined,
      actions: ['tap', 'scrollDown'],
      page: ShoppingDemo(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agent Demos'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(demo.icon),
              ),
              title: Text(demo.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(demo.subtitle),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: demo.actions
                        .map((a) => Chip(
                              label: Text(a),
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => demo.page),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> actions;
  final Widget page;

  const _DemoEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actions,
    required this.page,
  });
}
