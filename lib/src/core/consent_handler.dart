import '../models/action_descriptor.dart';

/// Strategy for requesting user consent before agent actions.
///
/// Implement this interface to display a confirmation dialog, overlay,
/// or any other consent mechanism before the agent executes actions.
///
/// ```dart
/// class DialogConsentHandler implements ConsentHandler {
///   @override
///   Future<bool> requestConsent(List<ActionDescriptor> actions) async {
///     return await showDialog<bool>(...) ?? false;
///   }
/// }
/// ```
abstract class ConsentHandler {
  /// Request user consent for the given list of actions.
  ///
  /// Returns `true` if the user approves, `false` to skip/cancel.
  Future<bool> requestConsent(List<ActionDescriptor> actions);
}

/// Always-approve consent handler for testing or trusted environments.
class AutoApproveConsentHandler implements ConsentHandler {
  const AutoApproveConsentHandler();

  @override
  Future<bool> requestConsent(List<ActionDescriptor> actions) async => true;
}

/// Always-deny consent handler for locked-down environments.
class AutoDenyConsentHandler implements ConsentHandler {
  const AutoDenyConsentHandler();

  @override
  Future<bool> requestConsent(List<ActionDescriptor> actions) async => false;
}
