/// Describes an action the LLM wants to execute on the UI.
///
/// An [ActionDescriptor] is parsed from the LLM's function-call response.
/// It maps to a registered action in [ActionRegistry].
class ActionDescriptor {
  /// Action name (must match a registered action, e.g. "tap", "enterText").
  final String actionName;

  /// Arguments for the action (e.g. {"id": "42", "text": "Hello"}).
  final Map<String, dynamic> args;

  const ActionDescriptor({
    required this.actionName,
    this.args = const {},
  });

  /// Parse from LLM JSON response.
  ///
  /// Expected format: `{"action": "tap", "args": {"id": "42"}}`
  factory ActionDescriptor.fromJson(Map<String, dynamic> json) {
    return ActionDescriptor(
      actionName: json['action'] as String,
      args: (json['args'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Parse from OpenAI tool_call format.
  ///
  /// Expected: `{"name": "tap", "arguments": {"id": "42"}}`
  factory ActionDescriptor.fromToolCall(Map<String, dynamic> json) {
    return ActionDescriptor(
      actionName: json['name'] as String,
      args: (json['arguments'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'action': actionName,
        'args': args,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionDescriptor &&
          runtimeType == other.runtimeType &&
          actionName == other.actionName;

  @override
  int get hashCode => actionName.hashCode;

  @override
  String toString() => 'ActionDescriptor(action=$actionName, args=$args)';
}
