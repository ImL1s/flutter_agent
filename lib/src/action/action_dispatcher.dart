import '../models/action_descriptor.dart';
import '../models/widget_descriptor.dart';
import '../models/selector.dart';
import '../semantic/node_resolver.dart';
import 'action_registry.dart';

/// Dispatches [ActionDescriptor]s to their handlers after resolving target nodes.
///
/// Uses [NodeResolver] to find the target node in the tree, then delegates
/// to the [ActionRegistry] for execution.
///
/// ```dart
/// final dispatcher = ActionDispatcher(registry: registry);
/// final success = await dispatcher.dispatch(action, uiTree);
/// ```
class ActionDispatcher {
  final ActionRegistry registry;

  /// Last error message from a failed dispatch, if any.
  String? lastError;

  ActionDispatcher({required this.registry});

  /// Dispatch an action to its handler.
  ///
  /// Returns `true` if the action was executed successfully,
  /// `false` if the node was not found or action is not registered.
  /// On failure, [lastError] contains the reason.
  Future<bool> dispatch(
      ActionDescriptor action, WidgetDescriptor root) async {
    lastError = null;

    // Check if action is registered
    if (!registry.has(action.actionName)) {
      lastError = 'Action "${action.actionName}" not registered';
      return false;
    }

    // Resolve target node by ID from args
    final targetId = action.args['id'] as String?;
    if (targetId != null) {
      final node = NodeResolver.resolve(root, Selector.byId(targetId));
      if (node == null) {
        lastError = 'Node with id "$targetId" not found in tree';
        return false;
      }
    }

    // Execute the action
    try {
      await registry.execute(action.actionName, action.args);
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }
}
