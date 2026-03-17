import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Bridge between agent actions and Flutter's semantics performAction API.
///
/// Maps action name strings to [SemanticsAction] enums and executes
/// them via the live [SemanticsOwner].
///
/// If the targeted node doesn't support the requested action, the executor
/// automatically walks down the semantics tree to find the nearest
/// descendant that does. This handles the common Flutter pattern where
/// a [Semantics] label wrapper (e.g. `Semantics(label: 'Increment')`)
/// doesn't carry the tap handler — it's on a child node created by
/// the button's internal [InkWell] / [GestureDetector].
///
/// ```dart
/// final executor = SemanticsActionExecutor();
/// await executor.perform(42, SemanticsAction.tap); // taps node 42 or its tappable descendant
/// ```
class SemanticsActionExecutor {
  /// Map of supported action names to their SemanticsAction equivalents.
  static const Map<String, SemanticsAction> actionMap = {
    'tap': SemanticsAction.tap,
    'longPress': SemanticsAction.longPress,
    'scrollUp': SemanticsAction.scrollUp,
    'scrollDown': SemanticsAction.scrollDown,
    'scrollLeft': SemanticsAction.scrollLeft,
    'scrollRight': SemanticsAction.scrollRight,
    'focus': SemanticsAction.focus,
    'dismiss': SemanticsAction.dismiss,
    'setText': SemanticsAction.setText,
  };

  /// Perform a [SemanticsAction] on the node with the given [nodeId].
  ///
  /// If the node doesn't support the action, walks descendants to find
  /// the nearest node that does.
  ///
  /// Throws [StateError] if semantics are not enabled.
  Future<void> performAction(int nodeId, SemanticsAction action, {Object? actionArgs}) async {
    final binding = WidgetsBinding.instance;
    final owner = binding.pipelineOwner.semanticsOwner;
    if (owner == null) {
      throw StateError(
        'Semantics not enabled. Call SemanticsBinding.ensureSemantics() first.',
      );
    }

    final rootNode = owner.rootSemanticsNode;
    if (rootNode == null) {
      throw StateError('No root semantics node available.');
    }

    // Find the target node in the tree
    final target = _findNodeById(rootNode, nodeId);
    if (target != null) {
      final data = target.getSemanticsData();
      if (!data.hasAction(action)) {
        // Walk descendants to find one that supports this action
        final descendant = _findDescendantWithAction(target, action);
        if (descendant != null) {
          owner.performAction(descendant.id, action, actionArgs);
          return;
        }
        // No descendant has the action either — fall through to direct call
      }
    }

    // Either the node supports the action, or we couldn't find a better target
    owner.performAction(nodeId, action, actionArgs);
  }

  /// Perform a semantics action by name string.
  ///
  /// Throws [UnsupportedActionException] if the action name is unknown.
  Future<void> perform(int nodeId, String actionName) async {
    final action = actionMap[actionName];
    if (action == null) {
      throw UnsupportedActionException(actionName);
    }
    await performAction(nodeId, action);
  }

  /// Find a [SemanticsNode] by ID via DFS.
  static SemanticsNode? _findNodeById(SemanticsNode node, int id) {
    if (node.id == id) return node;
    SemanticsNode? result;
    node.visitChildren((child) {
      result ??= _findNodeById(child, id);
      return result == null;
    });
    return result;
  }

  /// Find the first descendant of [node] that supports [action] via BFS.
  static SemanticsNode? _findDescendantWithAction(
      SemanticsNode node, SemanticsAction action) {
    SemanticsNode? result;
    node.visitChildren((child) {
      final data = child.getSemanticsData();
      if (data.hasAction(action)) {
        result = child;
        return false; // stop
      }
      result ??= _findDescendantWithAction(child, action);
      return result == null;
    });
    return result;
  }

  /// Check if an action name is supported.
  static bool isSupported(String actionName) =>
      actionMap.containsKey(actionName);

  /// List all supported action names.
  static List<String> get supportedActions => actionMap.keys.toList();
}

/// Thrown when an unsupported action name is requested.
class UnsupportedActionException implements Exception {
  final String actionName;
  UnsupportedActionException(this.actionName);

  @override
  String toString() =>
      'UnsupportedActionException: "$actionName" is not a supported semantics action.';
}
