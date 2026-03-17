import '../models/widget_descriptor.dart';

/// Masks sensitive data in [WidgetDescriptor] trees before sending to LLM.
///
/// Default patterns mask emails, phone numbers, and credit card numbers.
/// Additional patterns can be provided via [extraPatterns].
///
/// Returns a new tree — the original is never mutated.
///
/// ```dart
/// final masker = SensitiveDataMasker();
/// final safe = masker.mask(uiTree);
/// // safe.label will have PII replaced with '•' characters
/// ```
class SensitiveDataMasker {
  /// Character used to replace sensitive data.
  final String maskChar;

  /// Built-in patterns for common PII.
  static final List<RegExp> _defaultPatterns = [
    // Email: user@domain.tld
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    // Phone: +1-555-123-4567, (555) 123-4567, 555.123.4567, etc.
    RegExp(r'(?:\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'),
    // Credit card: 4111-1111-1111-1111, 4111111111111111
    RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
  ];

  /// Combined patterns (defaults + extras).
  final List<RegExp> _patterns;

  SensitiveDataMasker({
    this.maskChar = '•',
    List<RegExp>? extraPatterns,
  }) : _patterns = [
          ..._defaultPatterns,
          if (extraPatterns != null) ...extraPatterns,
        ];

  /// Mask sensitive data in the entire tree.
  ///
  /// Returns a new [WidgetDescriptor] tree with PII replaced.
  WidgetDescriptor mask(WidgetDescriptor node) {
    return node.copyWith(
      label: _maskString(node.label),
      value: _maskString(node.value),
      hint: _maskString(node.hint),
      children: node.children.map(mask).toList(),
    );
  }

  /// Apply all patterns to a string, replacing matches with mask characters.
  String _maskString(String input) {
    if (input.isEmpty) return input;
    var result = input;
    for (final pattern in _patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        return maskChar * match.group(0)!.length;
      });
    }
    return result;
  }
}
