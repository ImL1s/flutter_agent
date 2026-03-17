import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import '../models/widget_descriptor.dart';

/// Traverses Flutter's live [SemanticsNode] tree and produces
/// a [WidgetDescriptor] tree for the agent.
///
/// The walker accesses the semantics tree through
/// [WidgetsBinding.instance.pipelineOwner.semanticsOwner] and
/// recursively converts each [SemanticsNode] into a [WidgetDescriptor].
class SemanticTreeWalker {
  /// Capture the current semantics tree as a [WidgetDescriptor] tree.
  ///
  /// Returns `null` if semantics are not enabled or the tree is empty.
  /// Make sure `SemanticsBinding.instance.ensureSemantics()` is called
  /// or the app is running with an active semantics client.
  WidgetDescriptor? capture() {
    final binding = WidgetsBinding.instance;
    final semanticsOwner = binding.pipelineOwner.semanticsOwner;
    if (semanticsOwner == null) return null;
    final root = semanticsOwner.rootSemanticsNode;
    if (root == null) return null;
    return _walk(root);
  }

  /// Recursively convert a [SemanticsNode] subtree.
  WidgetDescriptor _walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    final actionNames = <String>[];

    // Check which SemanticsActions are available on this node.
    for (final action in SemanticsAction.values) {
      if (data.hasAction(action)) {
        actionNames.add(_actionName(action));
      }
    }

    // Explicitly add 'setText' to text fields so the LLM knows it can type here
    if (data.hasFlag(SemanticsFlag.isTextField) && !actionNames.contains('setText')) {
      actionNames.add('setText');
    }

    // Capture toggle / checkbox / enabled states
    bool? isToggled;
    bool? isChecked;
    bool? isEnabled;

    if (data.hasFlag(SemanticsFlag.hasToggledState)) {
      isToggled = data.hasFlag(SemanticsFlag.isToggled);
    }
    if (data.hasFlag(SemanticsFlag.hasCheckedState)) {
      isChecked = data.hasFlag(SemanticsFlag.isChecked);
    }
    if (data.hasFlag(SemanticsFlag.hasEnabledState)) {
      isEnabled = data.hasFlag(SemanticsFlag.isEnabled);
    }

    return WidgetDescriptor(
      id: node.id.toString(),
      role: _inferRole(data),
      label: data.label,
      hint: data.hint,
      value: data.value,
      actions: actionNames,
      children: _getChildren(node).map(_walk).toList(),
      isToggled: isToggled,
      isChecked: isChecked,
      isEnabled: isEnabled,
    );
  }

  /// Infer a human-readable role from [SemanticsData] flags.
  String _inferRole(SemanticsData data) {
    if (data.hasFlag(SemanticsFlag.isButton)) return 'button';
    if (data.hasFlag(SemanticsFlag.isTextField)) return 'textField';
    if (data.hasFlag(SemanticsFlag.isSlider)) return 'slider';
    if (data.hasFlag(SemanticsFlag.isLink)) return 'link';
    if (data.hasFlag(SemanticsFlag.isHeader)) return 'header';
    if (data.hasFlag(SemanticsFlag.isImage)) return 'image';
    if (data.hasFlag(SemanticsFlag.hasCheckedState)) return 'checkbox';
    if (data.hasFlag(SemanticsFlag.hasToggledState)) return 'toggle';
    return 'generic';
  }

  /// Get the immediate children of a [SemanticsNode].
  List<SemanticsNode> _getChildren(SemanticsNode node) {
    final children = <SemanticsNode>[];
    node.visitChildren((child) {
      children.add(child);
      return true;
    });
    return children;
  }

  /// Convert a [SemanticsAction] to a readable name string.
  String _actionName(SemanticsAction action) {
    return action.name;
  }
}
