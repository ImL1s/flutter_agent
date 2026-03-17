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

/// Structured diff result showing exactly what changed between two UI trees.
class VerificationDetail {
  final VerificationResult result;
  final List<String> changedNodeIds;
  final List<String> addedNodeIds;
  final List<String> removedNodeIds;

  const VerificationDetail({
    required this.result,
    this.changedNodeIds = const [],
    this.addedNodeIds = const [],
    this.removedNodeIds = const [],
  });

  /// Compare two [WidgetDescriptor] trees and produce a detailed diff.
  factory VerificationDetail.compare({
    required WidgetDescriptor before,
    required WidgetDescriptor after,
  }) {
    final changed = <String>[];
    final added = <String>[];
    final removed = <String>[];

    _diffNodes(before, after, changed, added, removed);

    final hasChanges = changed.isNotEmpty || added.isNotEmpty || removed.isNotEmpty;
    return VerificationDetail(
      result: hasChanges ? VerificationResult.changed : VerificationResult.unchanged,
      changedNodeIds: changed,
      addedNodeIds: added,
      removedNodeIds: removed,
    );
  }

  static void _diffNodes(
    WidgetDescriptor before,
    WidgetDescriptor after,
    List<String> changed,
    List<String> added,
    List<String> removed,
  ) {
    // Check if this node's properties changed
    if (before.label != after.label ||
        before.value != after.value ||
        before.role != after.role ||
        before.hint != after.hint) {
      changed.add(after.id);
    }

    // Build child maps by ID
    final beforeChildren = {for (final c in before.children) c.id: c};
    final afterChildren = {for (final c in after.children) c.id: c};

    // Find added children
    for (final id in afterChildren.keys) {
      if (!beforeChildren.containsKey(id)) {
        added.add(id);
        _collectAllIds(afterChildren[id]!, added);
      }
    }

    // Find removed children
    for (final id in beforeChildren.keys) {
      if (!afterChildren.containsKey(id)) {
        removed.add(id);
        _collectAllIds(beforeChildren[id]!, removed);
      }
    }

    // Recurse into common children
    for (final id in beforeChildren.keys) {
      if (afterChildren.containsKey(id)) {
        _diffNodes(beforeChildren[id]!, afterChildren[id]!, changed, added, removed);
      }
    }
  }

  /// Collect all descendant IDs (for added/removed subtrees).
  static void _collectAllIds(WidgetDescriptor node, List<String> ids) {
    for (final child in node.children) {
      ids.add(child.id);
      _collectAllIds(child, ids);
    }
  }
}
