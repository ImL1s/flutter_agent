import 'package:flutter/material.dart';
import '../agent_demo_base.dart';

/// Chat/IM Demo — tests `setText` + `tap` actions.
///
/// Agent task: Type a message and send it.
class ChatDemo extends StatefulWidget {
  const ChatDemo({super.key});

  @override
  State<ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<ChatDemo> {
  final List<_ChatMessage> _messages = [
    _ChatMessage('Hey! How are you?', false),
    _ChatMessage("I'm good, thanks! Working on the Flutter Agent.", true),
    _ChatMessage('That sounds interesting! Can you show me a demo?', false),
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(_ChatMessage(text, true));
        _controller.clear();
      });
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgentDemoScaffold(
      title: 'Chat Demo',
      agentTask:
          "Type 'Hello! The agent is working great!' in the message input field and then tap the Send button.",
      maxSteps: 8,
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Semantics(
                  label: msg.isMe ? 'My message' : 'Their message',
                  value: msg.text,
                  child: Align(
                    alignment:
                        msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isMe
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg.text),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Message input',
                    textField: true,
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Send message',
                  button: true,
                  child: FilledButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
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

class _ChatMessage {
  final String text;
  final bool isMe;
  _ChatMessage(this.text, this.isMe);
}
