import '../models/widget_descriptor.dart';
import '../models/action_descriptor.dart';
import '../action/action_registry.dart';
import '../llm/llm_client.dart';

/// Constructs LLM prompts from the current UI state and parses responses.
///
/// The [Planner] is responsible for:
/// 1. Formatting the [WidgetDescriptor] tree into a readable text prompt
/// 2. Attaching available tool schemas from [ActionRegistry]
/// 3. Sending the prompt to the [LLMClient]
/// 4. Returning parsed [ActionDescriptor] list
class Planner {
  final LLMClient llmClient;
  final ActionRegistry actionRegistry;

  Planner({required this.llmClient, required this.actionRegistry});

  /// Build a prompt from the current UI state and task, send to LLM,
  /// and return the parsed action descriptors.
  Future<List<ActionDescriptor>> plan({
    required WidgetDescriptor uiState,
    required String task,
  }) async {
    final prompt = buildPrompt(uiState, task);
    final toolSchemas = actionRegistry.toToolSchemas();
    return llmClient.requestActions(
      prompt: prompt,
      toolSchemas: toolSchemas,
    );
  }

  /// Build the text prompt from the UI state and task.
  ///
  /// Visible for testing.
  String buildPrompt(WidgetDescriptor uiState, String task) {
    final uiDescription = _formatTree(uiState, indent: 0);
    return '''Current UI state:
$uiDescription
Available actions: ${actionRegistry.registeredActions.join(', ')}

Task: $task

Analyze the UI state and use the available tools to accomplish the task. Be precise with node IDs.''';
  }

  /// Format a [WidgetDescriptor] tree as indented text.
  String _formatTree(WidgetDescriptor node, {required int indent}) {
    final prefix = '  ' * indent;
    final buf = StringBuffer();
    buf.write('$prefix- [${node.role}] id=${node.id} label="${node.label}"');
    if (node.value.isNotEmpty) buf.write(' value="${node.value}"');
    if (node.hint.isNotEmpty) buf.write(' hint="${node.hint}"');
    if (node.actions.isNotEmpty) buf.write(' actions=${node.actions}');
    buf.writeln();
    for (final child in node.children) {
      buf.write(_formatTree(child, indent: indent + 1));
    }
    return buf.toString();
  }
}
