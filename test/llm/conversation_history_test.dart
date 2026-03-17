import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

// RED: This import will fail until we create the file
// ignore: uri_does_not_exist

void main() {
  late ConversationHistory history;

  setUp(() {
    history = ConversationHistory();
  });

  group('initialization', () {
    test('starts empty', () {
      expect(history.length, 0);
      expect(history.toMessages(), isEmpty);
    });
  });

  group('addUserMessage', () {
    test('adds user message', () {
      history.addUserMessage('Fill in the login form');
      expect(history.length, 1);
      final messages = history.toMessages();
      expect(messages.first['role'], 'user');
      expect(messages.first['content'], 'Fill in the login form');
    });
  });

  group('addAssistantToolCalls', () {
    test('adds assistant tool calls in OpenAI format', () {
      final actions = [
        const ActionDescriptor(
          actionName: 'enterText',
          args: {'id': '2', 'text': 'hello'},
        ),
      ];
      history.addAssistantToolCalls(actions);
      expect(history.length, 1);
      final messages = history.toMessages();
      final msg = messages.first;
      expect(msg['role'], 'assistant');
      expect(msg['tool_calls'], isNotNull);
      final toolCalls = msg['tool_calls'] as List;
      expect(toolCalls, hasLength(1));
      expect(toolCalls.first['function']['name'], 'enterText');
    });

    test('includes arguments as JSON string', () {
      final actions = [
        const ActionDescriptor(
          actionName: 'tap',
          args: {'id': '5'},
        ),
      ];
      history.addAssistantToolCalls(actions);
      final toolCalls = history.toMessages().first['tool_calls'] as List;
      final argsStr = toolCalls.first['function']['arguments'] as String;
      expect(argsStr, contains('"id"'));
    });
  });

  group('addToolResult', () {
    test('adds tool result message', () {
      history.addToolResult('call_123', 'Action succeeded');
      expect(history.length, 1);
      final msg = history.toMessages().first;
      expect(msg['role'], 'tool');
      expect(msg['tool_call_id'], 'call_123');
      expect(msg['content'], 'Action succeeded');
    });
  });

  group('multi-turn ordering', () {
    test('toMessages returns messages in order', () {
      history.addUserMessage('Tap Login');
      history.addAssistantToolCalls([
        const ActionDescriptor(actionName: 'tap', args: {'id': '2'}),
      ]);
      history.addToolResult('call_1', 'OK');
      history.addUserMessage('Now enter password');

      final messages = history.toMessages();
      expect(messages, hasLength(4));
      expect(messages[0]['role'], 'user');
      expect(messages[1]['role'], 'assistant');
      expect(messages[2]['role'], 'tool');
      expect(messages[3]['role'], 'user');
    });
  });

  group('maxTurns eviction', () {
    test('evicts oldest when maxTurns exceeded', () {
      final bounded = ConversationHistory(maxTurns: 3);
      bounded.addUserMessage('Message 1');
      bounded.addUserMessage('Message 2');
      bounded.addUserMessage('Message 3');
      bounded.addUserMessage('Message 4'); // should evict Message 1

      expect(bounded.length, 3);
      final messages = bounded.toMessages();
      expect(messages.first['content'], 'Message 2');
      expect(messages.last['content'], 'Message 4');
    });
  });

  group('clear', () {
    test('clear resets history', () {
      history.addUserMessage('Test');
      history.addUserMessage('Test 2');
      expect(history.length, 2);

      history.clear();
      expect(history.length, 0);
      expect(history.toMessages(), isEmpty);
    });
  });
  group('tool call ID uniqueness', () {
    test('IDs are unique across multiple addAssistantToolCalls calls', () {
      history.addAssistantToolCalls([
        const ActionDescriptor(actionName: 'tap', args: {'id': '1'}),
        const ActionDescriptor(actionName: 'tap', args: {'id': '2'}),
      ]);
      history.addAssistantToolCalls([
        const ActionDescriptor(actionName: 'tap', args: {'id': '3'}),
      ]);

      final messages = history.toMessages();
      final allIds = <String>{};
      for (final msg in messages) {
        final calls = msg['tool_calls'] as List?;
        if (calls != null) {
          for (final call in calls) {
            final id = call['id'] as String;
            expect(allIds.contains(id), isFalse,
                reason: 'Duplicate tool call ID: $id');
            allIds.add(id);
          }
        }
      }
      expect(allIds, hasLength(3)); // 3 unique IDs total
    });
  });
}
