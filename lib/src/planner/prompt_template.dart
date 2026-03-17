import '../models/widget_descriptor.dart';

/// Abstract interface for prompt formatting strategies.
///
/// Implement this to customize how the agent describes UI state and tasks
/// to the LLM.
///
/// ```dart
/// final template = CustomPromptTemplate(
///   format: 'UI: {ui}\nDo this: {task}\nTools: {actions}',
/// );
/// ```
abstract class PromptTemplate {
  /// Format a prompt from UI state, task, and available action names.
  String format({
    required WidgetDescriptor uiState,
    required String task,
    required List<String> actionNames,
  });
}

/// Default prompt template matching the original Planner.buildPrompt() format.
class DefaultPromptTemplate implements PromptTemplate {
  const DefaultPromptTemplate();

  @override
  String format({
    required WidgetDescriptor uiState,
    required String task,
    required List<String> actionNames,
  }) {
    final uiDescription = _formatTree(uiState, indent: 0);
    return '''Current UI state:
$uiDescription
Available actions: ${actionNames.join(', ')}

Task: $task

Analyze the UI state and use the available tools to accomplish the task. Be precise with node IDs.''';
  }

  String _formatTree(WidgetDescriptor node, {required int indent}) {
    final prefix = '  ' * indent;
    final buf = StringBuffer();
    buf.write('$prefix- [${node.role}] id=${node.id} label="${node.label}"');
    if (node.value.isNotEmpty) buf.write(' value="${node.value}"');
    if (node.hint.isNotEmpty) buf.write(' hint="${node.hint}"');
    if (node.isToggled != null) buf.write(' toggled=${node.isToggled}');
    if (node.isChecked != null) buf.write(' checked=${node.isChecked}');
    if (node.isEnabled != null) buf.write(' enabled=${node.isEnabled}');
    if (node.actions.isNotEmpty) buf.write(' actions=${node.actions}');
    buf.writeln();
    for (final child in node.children) {
      buf.write(_formatTree(child, indent: indent + 1));
    }
    return buf.toString();
  }
}

/// User-customizable prompt template with placeholder substitution.
///
/// Supports `{ui}`, `{task}`, and `{actions}` placeholders.
class CustomPromptTemplate implements PromptTemplate {
  final String template;

  const CustomPromptTemplate({required this.template});

  @override
  String format({
    required WidgetDescriptor uiState,
    required String task,
    required List<String> actionNames,
  }) {
    final defaultFormatter = const DefaultPromptTemplate();
    final uiText = defaultFormatter._formatTree(uiState, indent: 0);

    return template
        .replaceAll('{ui}', uiText.trim())
        .replaceAll('{task}', task)
        .replaceAll('{actions}', actionNames.join(', '));
  }
}
