import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:flutter_agent/src/verifier/verifier.dart';
import 'package:flutter_agent/src/semantic/semantic_tree_walker.dart';
import 'package:flutter_agent/src/models/widget_descriptor.dart';

class MockSemanticTreeWalker extends Mock implements SemanticTreeWalker {}

void main() {
  late MockSemanticTreeWalker mockWalker;
  late Verifier verifier;

  setUp(() {
    mockWalker = MockSemanticTreeWalker();
    verifier = Verifier(treeWalker: mockWalker);
  });

  group('Verifier', () {
    test('returns changed when states differ', () {
      const before = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      const after =
          WidgetDescriptor(id: '1', role: 'button', label: 'Done');

      final result = verifier.verify(before: before, after: after);
      expect(result, VerificationResult.changed);
    });

    test('returns unchanged when states are identical', () {
      const before = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      const after = WidgetDescriptor(id: '1', role: 'button', label: 'OK');

      final result = verifier.verify(before: before, after: after);
      expect(result, VerificationResult.unchanged);
    });

    test('returns error when before is null', () {
      const after = WidgetDescriptor(id: '1', role: 'button', label: 'OK');

      final result = verifier.verify(before: null, after: after);
      expect(result, VerificationResult.error);
    });

    test('returns error when after is null', () {
      const before = WidgetDescriptor(id: '1', role: 'button', label: 'OK');

      final result = verifier.verify(before: before, after: null);
      expect(result, VerificationResult.error);
    });

    test('returns error when both null', () {
      final result = verifier.verify(before: null, after: null);
      expect(result, VerificationResult.error);
    });

    test('detects change in children', () {
      const before = WidgetDescriptor(
        id: '1',
        role: 'generic',
        label: 'Parent',
        children: [
          WidgetDescriptor(id: '2', role: 'button', label: 'A'),
        ],
      );
      const after = WidgetDescriptor(
        id: '1',
        role: 'generic',
        label: 'Parent',
        children: [
          WidgetDescriptor(id: '2', role: 'button', label: 'B'),
        ],
      );

      final result = verifier.verify(before: before, after: after);
      expect(result, VerificationResult.changed);
    });

    test('captureAndVerify uses tree walker', () {
      const previous =
          WidgetDescriptor(id: '1', role: 'button', label: 'Old');
      const current =
          WidgetDescriptor(id: '1', role: 'button', label: 'New');

      when(() => mockWalker.capture()).thenReturn(current);

      final result =
          verifier.captureAndVerify(previousState: previous);
      expect(result, VerificationResult.changed);
      verify(() => mockWalker.capture()).called(1);
    });
  });
}
