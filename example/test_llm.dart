import 'package:ai_flutter_agent/ai_flutter_agent.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test LLM multi-turn', () async {
    final client = OpenAILLMClient(
      apiKey: 'sk-test',
      baseUrl: 'http://127.0.0.1:1234/v1',
      model: 'local-model',
    );

    final schemas = [
      {
        'type': 'function',
        'function': {
          'name': 'tap',
          'description': 'Tap an element',
          'parameters': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'}
            },
            'required': ['id']
          }
        }
      }
    ];

    final messages = [
      {
        'role': 'user', 
        'content': 'Task: Click Increment 3 times.\nState: Node 2 is Increment'
      },
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 'call_0',
            'type': 'function',
            'function': {'name': 'tap', 'arguments': '{"id": "2"}'}
          }
        ]
      },
      {
        'role': 'tool',
        'tool_call_id': 'call_0',
        'content': 'Success'
      },
      {
        'role': 'user',
        'content': 'Task: Click Increment 3 times.\nState: Node 2 is Increment. Current value is 1.'
      }
    ];

    try {
      final actions = await client.requestActions(
        prompt: 'Task update: now click it again', 
        toolSchemas: schemas,
        messages: messages,
      );
      print('Actions parsed: ${actions.map((e) => e.actionName).toList()}');
    } catch (e) {
      print('Failed: $e');
    }
  });
}
