import '../models/action_descriptor.dart';
import 'llm_client.dart';

/// Extension of [LLMClient] that supports streaming responses.
///
/// Implementations can yield [ActionDescriptor]s as they arrive from the LLM,
/// enabling execute-as-received patterns that reduce perceived latency.
///
/// ```dart
/// final client = MyStreamingClient();
/// await for (final action in client.requestActionsStream(
///   prompt: prompt,
///   toolSchemas: schemas,
/// )) {
///   await executor.executeSingle(action);
/// }
/// ```
abstract class StreamingLLMClient extends LLMClient {
  /// Stream action descriptors as they arrive from the LLM.
  ///
  /// This allows the executor to begin processing actions before the
  /// full response is received, reducing end-to-end latency.
  Stream<ActionDescriptor> requestActionsStream({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
    List<Map<String, dynamic>>? messages,
  });
}
