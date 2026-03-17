/// Callback signature for registered actions.
///
/// Actions receive a map of arguments (e.g. `{"id": "42", "text": "hello"}`)
/// and return a Future that completes when the action finishes.
typedef ActionFunction = Future<void> Function(Map<String, dynamic> args);

/// Manages the set of actions available to the agent.
///
/// Only actions registered here can be executed — this serves as an
/// **action whitelist** to prevent the LLM from invoking arbitrary operations.
///
/// ```dart
/// final registry = ActionRegistry();
/// registry.register('tap', (args) async {
///   final nodeId = args['id'] as String;
///   // perform tap on the node
/// });
/// ```
class ActionRegistry {
  final Map<String, _ActionEntry> _actions = {};

  /// Register an action with a name, function, and optional parameter schema.
  void register(
    String name,
    ActionFunction fn, {
    String description = '',
    Map<String, Map<String, String>>? parameterSchema,
  }) {
    _actions[name] = _ActionEntry(
      fn: fn,
      description: description.isEmpty ? 'Perform the $name action on a UI element.' : description,
      parameterSchema: parameterSchema ??
          {
            'id': {'type': 'string', 'description': 'Target node ID'},
          },
    );
  }

  /// Unregister an action by name.
  void unregister(String name) {
    _actions.remove(name);
  }

  /// Check if an action is registered.
  bool has(String name) => _actions.containsKey(name);

  /// Execute a registered action. Throws [UnregisteredActionException] if not found.
  Future<void> execute(String name, Map<String, dynamic> args) async {
    final entry = _actions[name];
    if (entry == null) {
      throw UnregisteredActionException(name);
    }
    await entry.fn(args);
  }

  /// List all registered action names.
  List<String> get registeredActions => _actions.keys.toList();

  /// Export action definitions as OpenAI-compatible tool schemas.
  ///
  /// These schemas are sent alongside the prompt so the LLM knows
  /// which functions it can call and what parameters they accept.
  List<Map<String, dynamic>> toToolSchemas() {
    return _actions.entries.map((e) {
      final properties = <String, dynamic>{};
      final required = <String>[];
      for (final param in e.value.parameterSchema.entries) {
        properties[param.key] = param.value;
        required.add(param.key);
      }
      return {
        'type': 'function',
        'function': {
          'name': e.key,
          'description': e.value.description,
          'parameters': {
            'type': 'object',
            'properties': properties,
            'required': required,
          },
        },
      };
    }).toList();
  }
}

class _ActionEntry {
  final ActionFunction fn;
  final String description;
  final Map<String, Map<String, String>> parameterSchema;

  _ActionEntry({
    required this.fn,
    required this.description,
    required this.parameterSchema,
  });
}

/// Thrown when attempting to execute an action not in the registry (whitelist).
class UnregisteredActionException implements Exception {
  final String actionName;
  UnregisteredActionException(this.actionName);

  @override
  String toString() =>
      'UnregisteredActionException: "$actionName" is not registered in the action whitelist.';
}
