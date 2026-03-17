import '../models/widget_descriptor.dart';
import '../models/selector.dart';

/// Resolves [WidgetDescriptor] nodes from a tree using a [Selector].
///
/// Walks the tree recursively to find nodes matching the selector strategy.
///
/// ```dart
/// final node = NodeResolver.resolve(tree, Selector.byId('5'));
/// final buttons = NodeResolver.resolveAll(
///   tree, Selector(by: SelectorType.role, value: 'button'));
/// ```
class NodeResolver {
  /// Find the first node matching [selector] in the [root] tree.
  ///
  /// Returns `null` if no match is found.
  static WidgetDescriptor? resolve(
      WidgetDescriptor root, Selector selector) {
    if (_matches(root, selector)) return root;
    for (final child in root.children) {
      final result = resolve(child, selector);
      if (result != null) return result;
    }
    return null;
  }

  /// Find all nodes matching [selector] in the [root] tree.
  static List<WidgetDescriptor> resolveAll(
      WidgetDescriptor root, Selector selector) {
    final results = <WidgetDescriptor>[];
    _collectAll(root, selector, results);
    return results;
  }

  static void _collectAll(WidgetDescriptor node, Selector selector,
      List<WidgetDescriptor> results) {
    if (_matches(node, selector)) results.add(node);
    for (final child in node.children) {
      _collectAll(child, selector, results);
    }
  }

  static bool _matches(WidgetDescriptor node, Selector selector) {
    switch (selector.by) {
      case SelectorType.id:
        return node.id.toString() == selector.value;
      case SelectorType.label:
        return node.label == selector.value;
      case SelectorType.role:
        return node.role == selector.value;
      case SelectorType.key:
        // Key matching uses label as fallback since WidgetDescriptor
        // doesn't store Key directly — can be extended later
        return node.label == selector.value;
    }
  }
}
