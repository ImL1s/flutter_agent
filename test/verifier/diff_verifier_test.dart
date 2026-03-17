import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/flutter_agent.dart';

void main() {
  group('DiffVerifier (verifyDetailed)', () {
    test('detects no changes', () {
      const tree = WidgetDescriptor(id: '1', role: 'button', label: 'OK');
      final detail = VerificationDetail.compare(before: tree, after: tree);

      expect(detail.result, VerificationResult.unchanged);
      expect(detail.changedNodeIds, isEmpty);
      expect(detail.addedNodeIds, isEmpty);
      expect(detail.removedNodeIds, isEmpty);
    });

    test('detects added node', () {
      const before = WidgetDescriptor(id: '0', role: 'generic', label: 'Root');
      const after = WidgetDescriptor(
        id: '0', role: 'generic', label: 'Root',
        children: [WidgetDescriptor(id: '1', role: 'button', label: 'New')],
      );

      final detail = VerificationDetail.compare(before: before, after: after);

      expect(detail.result, VerificationResult.changed);
      expect(detail.addedNodeIds, contains('1'));
    });

    test('detects removed node', () {
      const before = WidgetDescriptor(
        id: '0', role: 'generic', label: 'Root',
        children: [WidgetDescriptor(id: '1', role: 'button', label: 'Gone')],
      );
      const after = WidgetDescriptor(id: '0', role: 'generic', label: 'Root');

      final detail = VerificationDetail.compare(before: before, after: after);

      expect(detail.result, VerificationResult.changed);
      expect(detail.removedNodeIds, contains('1'));
    });

    test('detects changed value', () {
      const before = WidgetDescriptor(
        id: '1', role: 'textField', label: 'Name', value: '',
      );
      const after = WidgetDescriptor(
        id: '1', role: 'textField', label: 'Name', value: 'Alice',
      );

      final detail = VerificationDetail.compare(before: before, after: after);

      expect(detail.result, VerificationResult.changed);
      expect(detail.changedNodeIds, contains('1'));
    });

    test('detects deep nested change', () {
      const before = WidgetDescriptor(
        id: '0', role: 'generic', label: 'Root',
        children: [
          WidgetDescriptor(
            id: '1', role: 'generic', label: 'Container',
            children: [
              WidgetDescriptor(id: '2', role: 'button', label: 'Old'),
            ],
          ),
        ],
      );
      const after = WidgetDescriptor(
        id: '0', role: 'generic', label: 'Root',
        children: [
          WidgetDescriptor(
            id: '1', role: 'generic', label: 'Container',
            children: [
              WidgetDescriptor(id: '2', role: 'button', label: 'New'),
            ],
          ),
        ],
      );

      final detail = VerificationDetail.compare(before: before, after: after);

      expect(detail.result, VerificationResult.changed);
      expect(detail.changedNodeIds, contains('2'));
    });
  });
}
