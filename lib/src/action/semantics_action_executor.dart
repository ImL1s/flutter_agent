import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Bridge between agent actions and Flutter's semantics performAction API.
///
/// Maps action name strings to [SemanticsAction] enums and executes
/// them via the live [SemanticsOwner].
///
/// ```dart
/// final executor = SemanticsActionExecutor();
/// await executor.perform(42, 'tap'); // taps node 42
/// ```
class SemanticsActionExecutor {
  /// Map of supported action names to their SemanticsAction equivalents.
  static const Map<String, SemanticsAction> _actionMap = {
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

  /// Perform a semantics action on the node with the given [nodeId].
  ///
  /// Throws [UnsupportedActionException] if the action name is unknown.
  /// Throws [StateError] if semantics are not enabled.
  Future<void> perform(int nodeId, String actionName) async {
    final action = _actionMap[actionName];
    if (action == null) {
      throw UnsupportedActionException(actionName);
    }

    final binding = WidgetsBinding.instance;
    final owner = binding.pipelineOwner.semanticsOwner;
    if (owner == null) {
      throw StateError(
        'Semantics not enabled. Call SemanticsBinding.ensureSemantics() first.',
      );
    }

    owner.performAction(nodeId, action);
  }

  /// Check if an action name is supported.
  static bool isSupported(String actionName) =>
      _actionMap.containsKey(actionName);

  /// List all supported action names.
  static List<String> get supportedActions => _actionMap.keys.toList();
}

/// Thrown when an unsupported action name is requested.
class UnsupportedActionException implements Exception {
  final String actionName;
  UnsupportedActionException(this.actionName);

  @override
  String toString() =>
      'UnsupportedActionException: "$actionName" is not a supported semantics action.';
}
