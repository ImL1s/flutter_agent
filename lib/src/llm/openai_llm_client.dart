import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/action_descriptor.dart';
import 'llm_client.dart';

/// OpenAI API implementation of [LLMClient].
///
/// Uses the Chat Completions endpoint with function-calling (tools) to
/// request structured actions from models like GPT-4o.
///
/// ```dart
/// final client = OpenAILLMClient(apiKey: 'sk-...');
/// final actions = await client.requestActions(
///   prompt: 'Tap the Submit button',
///   toolSchemas: registry.toToolSchemas(),
/// );
/// ```
class OpenAILLMClient implements LLMClient {
  /// OpenAI API key.
  final String apiKey;

  /// Model to use (default: gpt-4o).
  final String model;

  /// Base URL for the API (allows custom endpoints / proxies).
  final String baseUrl;

  /// System prompt instructing the model to act as a UI agent.
  final String systemPrompt;

  final http.Client _httpClient;

  OpenAILLMClient({
    required this.apiKey,
    this.model = 'gpt-4o',
    this.baseUrl = 'https://api.openai.com/v1',
    this.systemPrompt = 'You are a UI automation agent that controls a Flutter app via semantics actions. '
        'Rules: '
        '1) Analyze the Current UI state tree. Each node has an id, role, label, value, and available actions. '
        '2) Perform ONE action per step using the provided tools. Use the exact node ID from the UI tree. '
        '3) For setText, you must first target the correct text field node ID, then provide the text. '
        '4) After each action, the UI state will update. Re-analyze and continue. '
        '5) When the task is FULLY COMPLETE, respond with plain text (no tool calls) to signal completion. '
        '6) If an action did not change the UI, try a different node ID or approach. '
        'Be precise with node IDs — use the id values shown in the UI tree.',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  }) async {
    final allMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      if (messages != null) ...messages,
      {'role': 'user', 'content': prompt},
    ];

    final requestBody = <String, dynamic>{
      'model': model,
      'messages': allMessages,
    };

    // Only include tools if there are schemas — some local LLM servers
    // reject empty tool arrays.
    if (toolSchemas.isNotEmpty) {
      requestBody['tools'] = toolSchemas;
      requestBody['tool_choice'] = 'auto';
    }

    final body = jsonEncode(requestBody);
    
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    ).timeout(const Duration(seconds: 30), onTimeout: () {
      throw LLMException('HTTP Request to $baseUrl timed out after 30 seconds.');
    });
    
    if (response.statusCode != 200) {
      throw LLMException(
        'OpenAI API error ${response.statusCode}: ${response.body}',
      );
    }
    
    final responseBody = response.body;
    try {
      File('/data/user/0/com.example.ai_flutter_agent_example/cache/llm_log.txt').writeAsStringSync(
        '===== LLM Raw Response =====\n$responseBody\n=======================\n\n',
        mode: FileMode.append,
      );
    } catch (e) {
      print('Could not write LLM log to file: $e');
    }

    print('===== LLM Raw Response =====');
    print(responseBody);
    print('=======================');

    return _parseResponse(response.body);
  }

  List<ActionDescriptor> _parseResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return [];

    final message = choices.first['message'] as Map<String, dynamic>;
    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls == null || toolCalls.isEmpty) {
      // LLM returned text instead of tool_calls — treat as task completion
      return [];
    }

    return toolCalls.map((tc) {
      final fn = tc['function'] as Map<String, dynamic>;
      final argsStr = fn['arguments'] as String? ?? '{}';
      Map<String, dynamic> args;
      try {
        args = jsonDecode(argsStr) as Map<String, dynamic>;
      } catch (_) {
        args = {};
      }
      return ActionDescriptor(
        actionName: fn['name'] as String,
        args: args,
      );
    }).toList();
  }

  /// Clean up HTTP resources.
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when LLM communication fails.
class LLMException implements Exception {
  final String message;
  LLMException(this.message);

  @override
  String toString() => 'LLMException: $message';
}
