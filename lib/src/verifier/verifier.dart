import 'dart:convert';
import '../models/widget_descriptor.dart';
import '../semantic/semantic_tree_walker.dart';

/// Result of a post-action verification check.
enum VerificationResult {
  /// The UI state changed after the action — likely success.
  changed,

  /// The UI state did not change — the action may have had no effect.
  unchanged,

  /// Could not capture state for comparison.
  error,
}

/// Verifies that agent actions had the intended effect on the UI.
///
/// After the [Executor] processes actions, the [Verifier] re-captures
/// the semantics tree and compares it to the pre-action snapshot.
class Verifier {
  final SemanticTreeWalker treeWalker;

  Verifier({required this.treeWalker});

  /// Compare two UI state snapshots.
  VerificationResult verify({
    required WidgetDescriptor? before,
    required WidgetDescriptor? after,
  }) {
    if (before == null || after == null) return VerificationResult.error;

    // Deep comparison via JSON serialization (jsonEncode ensures deterministic key order)
    final beforeJson = jsonEncode(before.toJson());
    final afterJson = jsonEncode(after.toJson());

    if (beforeJson == afterJson) {
      return VerificationResult.unchanged;
    }
    return VerificationResult.changed;
  }

  /// Capture the current UI state and compare with a previous snapshot.
  VerificationResult captureAndVerify({
    required WidgetDescriptor? previousState,
  }) {
    final current = treeWalker.capture();
    return verify(before: previousState, after: current);
  }
}
