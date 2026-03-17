import '../models/action_descriptor.dart';

/// Abstract interface for LLM communication.
///
/// Implementations handle the transport layer (HTTP, local inference, etc.)
/// and return parsed [ActionDescriptor] lists from the LLM response.
///
/// See [OpenAILLMClient] for the default cloud implementation.
abstract class LLMClient {
  /// Send a prompt with available tool schemas and receive action descriptors.
  ///
  /// [prompt] contains the current UI state description and user task.
  /// [toolSchemas] are OpenAI-compatible function definitions from [ActionRegistry].
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
  });
}
