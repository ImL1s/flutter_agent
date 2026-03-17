import 'package:flutter/semantics.dart';
import 'action_registry.dart';

/// Registers standard built-in actions that map to Flutter [SemanticsAction]s.
///
/// Call `BuiltInActions.registerDefaults(registry)` to populate an
/// [ActionRegistry] with the common actions: tap, longPress, scrollUp,
/// scrollDown, scrollLeft, scrollRight, setText, focus, dismiss.
///
/// ```dart
/// final registry = ActionRegistry();
/// BuiltInActions.registerDefaults(registry);
/// ```
class BuiltInActions {
  /// Map of action names to their SemanticsAction counterparts.
  static const Map<String, SemanticsAction> actionMap = {
    'tap': SemanticsAction.tap,
    'longPress': SemanticsAction.longPress,
    'scrollUp': SemanticsAction.scrollUp,
    'scrollDown': SemanticsAction.scrollDown,
    'scrollLeft': SemanticsAction.scrollLeft,
    'scrollRight': SemanticsAction.scrollRight,
    'focus': SemanticsAction.focus,
    'dismiss': SemanticsAction.dismiss,
  };

  /// Register all default actions on the given [registry].
  ///
  /// The optional [performAction] callback is used to actually execute
  /// semantics actions. In production, this calls
  /// `SemanticsOwner.performAction()`. In tests, provide a mock.
  static void registerDefaults(
    ActionRegistry registry, {
    Future<void> Function(int nodeId, SemanticsAction action)? performAction,
  }) {
    // Register semantics-based actions
    for (final entry in actionMap.entries) {
      registry.register(
        entry.key,
        (args) async {
          final nodeId = int.parse(args['id'].toString());
          if (performAction != null) {
            await performAction(nodeId, entry.value);
          }
        },
        description: 'Perform ${entry.key} on a UI element.',
      );
    }

    // Register setText (requires text parameter)
    registry.register(
      'setText',
      (args) async {
        final nodeId = int.parse(args['id'].toString());
        // text is available in args['text'] for the performAction handler
        if (performAction != null) {
          await performAction(nodeId, SemanticsAction.setText);
        }
      },
      description: 'Set text content of an input field.',
      parameterSchema: {
        'id': {'type': 'string', 'description': 'Target node ID'},
        'text': {'type': 'string', 'description': 'Text to set'},
      },
    );
  }

  /// List all built-in action names.
  static List<String> get allActionNames =>
      [...actionMap.keys, 'setText'];
}
