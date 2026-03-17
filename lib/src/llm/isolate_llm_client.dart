import 'dart:async';
import 'dart:isolate';
import '../models/action_descriptor.dart';
import 'llm_client.dart';

/// Wraps any [LLMClient] to execute LLM requests in a Dart [Isolate].
///
/// This prevents LLM processing (JSON parsing, response handling) from
/// blocking the UI thread in Flutter applications.
///
/// Note: The wrapped [LLMClient] must be constructable from serializable
/// parameters since Dart Isolates don't share memory.
///
/// ```dart
/// final isolatedClient = IsolateLLMClient(
///   factory: () => OpenAILLMClient(apiKey: 'sk-...'),
/// );
/// ```
class IsolateLLMClient implements LLMClient {
  /// Factory function that creates the inner [LLMClient] inside the isolate.
  final LLMClient Function() factory;

  IsolateLLMClient({required this.factory});

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  }) async {
    // For now, use compute-style pattern via Isolate.run (Dart 2.19+)
    // The factory creates a fresh LLMClient inside the isolate
    try {
      return await Isolate.run(() async {
        final client = factory();
        return client.requestActions(
          prompt: prompt,
          toolSchemas: toolSchemas,
          messages: messages,
        );
      });
    } catch (e) {
      // If isolate fails (e.g., closures not sendable), fall back to main thread
      final client = factory();
      return client.requestActions(
        prompt: prompt,
        toolSchemas: toolSchemas,
        messages: messages,
      );
    }
  }
}
