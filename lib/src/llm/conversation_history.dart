import 'dart:convert';
import '../models/action_descriptor.dart';

/// Manages multi-turn conversation history for LLM interactions.
///
/// Stores messages in OpenAI-compatible format so the LLM can see
/// what actions it took in previous turns.
///
/// ```dart
/// final history = ConversationHistory(maxTurns: 10);
/// history.addUserMessage('Fill in the login form');
/// history.addAssistantToolCalls(actions);
/// history.addToolResult('call_1', 'OK');
/// final messages = history.toMessages(); // pass to LLM
/// ```
class ConversationHistory {
  final List<Map<String, dynamic>> _messages = [];

  /// Monotonic counter for unique tool call IDs across all calls.
  int _nextCallId = 0;

  /// Maximum number of messages to keep. Oldest are evicted first.
  /// If null, no eviction is performed.
  final int? maxTurns;

  ConversationHistory({this.maxTurns});

  /// Number of messages in history.
  int get length => _messages.length;

  /// Add a user message.
  void addUserMessage(String content) {
    _messages.add({'role': 'user', 'content': content});
    _evictIfNeeded();
  }

  /// Add assistant tool calls from parsed [ActionDescriptor]s.
  ///
  /// Converts each action into OpenAI tool_call format.
  void addAssistantToolCalls(List<ActionDescriptor> actions) {
    final toolCalls = actions.map((action) {
      final callId = _nextCallId++;
      return {
        'id': 'call_$callId',
        'type': 'function',
        'function': {
          'name': action.actionName,
          'arguments': jsonEncode(action.args),
        },
      };
    }).toList();

    _messages.add({
      'role': 'assistant',
      'content': null,
      'tool_calls': toolCalls,
    });
    _evictIfNeeded();
  }

  /// Add a tool result message.
  void addToolResult(String toolCallId, String result) {
    _messages.add({
      'role': 'tool',
      'tool_call_id': toolCallId,
      'content': result,
    });
    _evictIfNeeded();
  }

  /// Return all messages in order for passing to the LLM.
  List<Map<String, dynamic>> toMessages() => List.unmodifiable(_messages);

  /// Clear all history.
  void clear() => _messages.clear();

  void _evictIfNeeded() {
    if (maxTurns != null) {
      while (_messages.length > maxTurns!) {
        _messages.removeAt(0);
      }
    }
  }
}
