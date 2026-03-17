import 'package:flutter/foundation.dart';

/// Represents a single node in the UI semantics tree.
///
/// Each [WidgetDescriptor] mirrors a Flutter [SemanticsNode], capturing
/// the node's identity, role, label, hint, value, available actions,
/// and child nodes. The agent uses this tree to understand the current UI.
class WidgetDescriptor {
  /// Unique node identifier (from [SemanticsNode.id]).
  final String id;

  /// Semantic role (e.g. "button", "textField", "slider", "generic").
  final String role;

  /// Accessibility label describing this element.
  final String label;

  /// Accessibility hint (e.g. "Double tap to activate").
  final String hint;

  /// Current value (e.g. slider position, text field content).
  final String value;

  /// List of available [SemanticsAction] names on this node.
  final List<String> actions;

  /// Child descriptors forming the subtree.
  final List<WidgetDescriptor> children;

  const WidgetDescriptor({
    required this.id,
    required this.role,
    required this.label,
    this.hint = '',
    this.value = '',
    this.actions = const [],
    this.children = const [],
  });

  /// Serialize to JSON for prompt construction.
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'label': label,
        if (hint.isNotEmpty) 'hint': hint,
        if (value.isNotEmpty) 'value': value,
        if (actions.isNotEmpty) 'actions': actions,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(),
      };

  /// Create a copy with modified fields.
  WidgetDescriptor copyWith({
    String? id,
    String? role,
    String? label,
    String? hint,
    String? value,
    List<String>? actions,
    List<WidgetDescriptor>? children,
  }) {
    return WidgetDescriptor(
      id: id ?? this.id,
      role: role ?? this.role,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      value: value ?? this.value,
      actions: actions ?? this.actions,
      children: children ?? this.children,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetDescriptor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          label == other.label &&
          hint == other.hint &&
          value == other.value &&
          listEquals(actions, other.actions) &&
          listEquals(children, other.children);

  @override
  int get hashCode =>
      id.hashCode ^
      role.hashCode ^
      label.hashCode ^
      hint.hashCode ^
      value.hashCode ^
      Object.hashAll(actions) ^
      Object.hashAll(children);

  @override
  String toString() => 'WidgetDescriptor(id=$id, role=$role, label="$label")';
}
