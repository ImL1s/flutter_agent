// ignore_for_file: avoid_print
/// E2E test: sends a mock UI tree to the local 9b model and verifies
/// the model returns valid tool calls.
///
/// Usage:  dart run test/e2e/local_llm_e2e.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'http://10.5.0.2:1234/v1';
const model = 'qwen3.5-9b-claude-4.6-opus-reasoning-distilled';

void main() async {
  print('═══════════════════════════════════════════════════');
  print(' Flutter Agent — Local 9B Model E2E Test');
  print('═══════════════════════════════════════════════════\n');

  // 1. Verify model is reachable
  print('Step 1: Checking model availability...');
  final modelsRes = await http.get(Uri.parse('$baseUrl/models'));
  if (modelsRes.statusCode != 200) {
    print('✗ Cannot reach model server at $baseUrl');
    return;
  }
  print('✓ Model server reachable\n');

  // 2. Build a mock UI state prompt
  const uiState = '''
Current UI state:
- [generic] id=1 label="Scaffold"
  - [header] id=2 label="Flutter Agent Demo"
  - [textField] id=3 label="Name" hint="Enter your name" value="" actions=[tap, setText]
  - [textField] id=4 label="Email" hint="Enter your email" value="" actions=[tap, setText]
  - [button] id=5 label="Submit" actions=[tap]
  - [generic] id=6 label="Status" value="Ready"

Available actions: tap, enterText

Task: Fill in the name field with "LLM Agent" and tap the Submit button.

Analyze the UI state and use the available tools to accomplish the task. Be precise with node IDs.''';

  final tools = [
    {
      'type': 'function',
      'function': {
        'name': 'tap',
        'description': 'Tap a UI element.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'Target node ID'},
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'enterText',
        'description': 'Enter text into a text field.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'Target node ID'},
            'text': {'type': 'string', 'description': 'Text to enter'},
          },
          'required': ['id', 'text'],
        },
      },
    },
  ];

  // 3. Send request to local model
  print('Step 2: Sending UI + task prompt to $model...');
  final body = jsonEncode({
    'model': model,
    'messages': [
      {
        'role': 'system',
        'content': 'You are a UI automation agent. '
            'Analyze the current UI state and return tool calls to interact with the app. '
            'Only use the provided tools. Be precise with node IDs.',
      },
      {'role': 'user', 'content': uiState},
    ],
    'tools': tools,
    'tool_choice': 'auto',
  });

  final res = await http.post(
    Uri.parse('$baseUrl/chat/completions'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  print('   HTTP ${res.statusCode}');
  if (res.statusCode != 200) {
    print('✗ API error: ${res.body}');
    return;
  }
  print('✓ Got response\n');

  // 4. Parse and validate tool calls
  print('Step 3: Parsing tool calls from response...');
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final message = (json['choices'] as List).first['message'] as Map<String, dynamic>;

  // Check for text content (model might respond with text instead of tool calls)
  if (message.containsKey('content') && message['content'] != null) {
    final content = message['content'] as String;
    if (content.isNotEmpty) {
      print('   Model text response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
    }
  }

  final toolCalls = message['tool_calls'] as List?;
  if (toolCalls == null || toolCalls.isEmpty) {
    print('⚠ Model returned no tool_calls. It may have responded with text only.');
    print('   Full response:');
    final prettyJson = const JsonEncoder.withIndent('  ').convert(message);
    print(prettyJson);
    return;
  }

  print('✓ Received ${toolCalls.length} tool call(s):\n');

  for (var i = 0; i < toolCalls.length; i++) {
    final tc = toolCalls[i] as Map<String, dynamic>;
    final fn = tc['function'] as Map<String, dynamic>;
    final name = fn['name'] as String;
    final argsStr = fn['arguments'] as String? ?? '{}';
    Map<String, dynamic> args;
    try {
      args = jsonDecode(argsStr) as Map<String, dynamic>;
    } catch (_) {
      args = {'_raw': argsStr};
    }

    print('   [$i] $name(${jsonEncode(args)})');

    // Validate
    if (name == 'enterText') {
      if (args.containsKey('id') && args.containsKey('text')) {
        print('       ✓ Valid enterText call');
      } else {
        print('       ✗ Missing required params (id, text)');
      }
    } else if (name == 'tap') {
      if (args.containsKey('id')) {
        print('       ✓ Valid tap call');
      } else {
        print('       ✗ Missing required param (id)');
      }
    } else {
      print('       ⚠ Unknown action: $name');
    }
  }

  print('\n═══════════════════════════════════════════════════');
  print(' E2E Test Complete');
  print('═══════════════════════════════════════════════════');
}
