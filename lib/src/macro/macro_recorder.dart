import 'dart:convert';
import '../models/action_descriptor.dart';

/// Records a sequence of [ActionDescriptor]s as a replayable macro.
///
/// ```dart
/// final recorder = MacroRecorder();
/// recorder.record(ActionDescriptor(actionName: 'tap', args: {'id': '1'}));
/// recorder.record(ActionDescriptor(actionName: 'setText', args: {'id': '2', 'text': 'hello'}));
/// final macro = recorder.toMacro('Login Flow');
/// ```
class MacroRecorder {
  final List<ActionDescriptor> _actions = [];

  /// Record an action.
  void record(ActionDescriptor action) => _actions.add(action);

  /// Number of recorded actions.
  int get length => _actions.length;

  /// Clear all recorded actions.
  void clear() => _actions.clear();

  /// Build a [Macro] from the recorded actions.
  Macro toMacro(String name) => Macro(name: name, actions: List.of(_actions));
}

/// A named, replayable sequence of actions.
class Macro {
  final String name;
  final List<ActionDescriptor> actions;
  final DateTime createdAt;

  Macro({
    required this.name,
    required this.actions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Number of actions in this macro.
  int get length => actions.length;

  /// Serialize this macro to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'actions': actions
            .map((a) => {'actionName': a.actionName, 'args': a.args})
            .toList(),
      };

  /// Deserialize a macro from JSON.
  factory Macro.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List).map((a) {
      final map = a as Map<String, dynamic>;
      return ActionDescriptor(
        actionName: map['actionName'] as String,
        args: Map<String, dynamic>.from(map['args'] as Map),
      );
    }).toList();

    return Macro(
      name: json['name'] as String,
      actions: actionsList,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Stores and retrieves macros as JSON strings.
class MacroStore {
  /// Serialize a macro to a JSON string.
  static String serialize(Macro macro) => jsonEncode(macro.toJson());

  /// Deserialize a macro from a JSON string.
  static Macro deserialize(String json) =>
      Macro.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
