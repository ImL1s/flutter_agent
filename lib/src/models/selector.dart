/// Strategy for locating a target [SemanticsNode].
enum SelectorType {
  /// Select by node ID (from [SemanticsNode.id]).
  id,

  /// Select by accessibility label.
  label,

  /// Select by semantic role (e.g. "button").
  role,

  /// Select by widget Key.
  key,
}

/// Defines how to locate a target node in the semantics tree.
///
/// Used by [ActionDescriptor] to specify which UI element to act upon.
class Selector {
  /// The selection strategy.
  final SelectorType by;

  /// The value to match against.
  final String value;

  const Selector({required this.by, required this.value});

  /// Parse from JSON: `{"by": "label", "value": "Submit"}`
  factory Selector.fromJson(Map<String, dynamic> json) {
    return Selector(
      by: SelectorType.values.firstWhere(
        (e) => e.name == json['by'],
        orElse: () => SelectorType.id,
      ),
      value: json['value'] as String,
    );
  }

  /// Create a selector that finds by node ID.
  factory Selector.byId(String id) =>
      Selector(by: SelectorType.id, value: id);

  /// Create a selector that finds by label text.
  factory Selector.byLabel(String label) =>
      Selector(by: SelectorType.label, value: label);

  Map<String, dynamic> toJson() => {'by': by.name, 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Selector &&
          runtimeType == other.runtimeType &&
          by == other.by &&
          value == other.value;

  @override
  int get hashCode => by.hashCode ^ value.hashCode;

  @override
  String toString() => 'Selector(by=${by.name}, value="$value")';
}
