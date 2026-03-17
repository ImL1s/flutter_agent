import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_client.dart';
import '../models/action_descriptor.dart';

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
    this.systemPrompt = 'You are a UI automation agent. '
        'Analyze the current UI state and return tool calls to interact with the app. '
        'Only use the provided tools. Be precise with node IDs.',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
  }) async {
    final requestBody = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
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
    );

    if (response.statusCode != 200) {
      throw LLMException(
        'OpenAI API error ${response.statusCode}: ${response.body}',
      );
    }

    return _parseResponse(response.body);
  }

  List<ActionDescriptor> _parseResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return [];

    final message = choices.first['message'] as Map<String, dynamic>;
    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls == null || toolCalls.isEmpty) return [];

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
