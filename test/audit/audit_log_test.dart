import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent/src/audit/audit_log.dart';

void main() {
  group('AuditLog', () {
    late AuditLog log;

    setUp(() {
      log = AuditLog();
    });

    test('starts empty', () {
      expect(log.entries, isEmpty);
      expect(log.length, 0);
    });

    test('logs a successful action', () {
      final ts = DateTime(2026, 3, 17);
      log.log(
        action: 'tap',
        args: {'id': '1'},
        timestamp: ts,
        success: true,
      );
      expect(log.length, 1);
      expect(log.entries.first.action, 'tap');
      expect(log.entries.first.success, true);
      expect(log.entries.first.error, isNull);
    });

    test('logs a failed action with error', () {
      final ts = DateTime(2026, 3, 17);
      log.log(
        action: 'scroll',
        args: {},
        timestamp: ts,
        success: false,
        error: 'Node not found',
      );
      expect(log.length, 1);
      expect(log.entries.first.success, false);
      expect(log.entries.first.error, 'Node not found');
    });

    test('failures returns only failed entries', () {
      final ts = DateTime(2026, 3, 17);
      log.log(action: 'tap', args: {}, timestamp: ts, success: true);
      log.log(
          action: 'scroll',
          args: {},
          timestamp: ts,
          success: false,
          error: 'err');
      log.log(action: 'tap', args: {}, timestamp: ts, success: true);
      expect(log.failures.length, 1);
      expect(log.failures.first.action, 'scroll');
    });

    test('clear removes all entries', () {
      final ts = DateTime(2026, 3, 17);
      log.log(action: 'tap', args: {}, timestamp: ts, success: true);
      log.log(action: 'tap', args: {}, timestamp: ts, success: true);
      expect(log.length, 2);
      log.clear();
      expect(log.length, 0);
    });

    test('entries list is unmodifiable', () {
      expect(() => log.entries.add(AuditEntry(
        action: 'x',
        args: {},
        timestamp: DateTime.now(),
        success: true,
      )), throwsA(isA<UnsupportedError>()));
    });

    test('AuditEntry toJson serializes correctly', () {
      final entry = AuditEntry(
        action: 'tap',
        args: {'id': '1'},
        timestamp: DateTime(2026, 3, 17, 10, 30),
        success: true,
      );
      final json = entry.toJson();
      expect(json['action'], 'tap');
      expect(json['success'], true);
      expect(json.containsKey('error'), false);
    });

    test('AuditEntry toJson includes error when present', () {
      final entry = AuditEntry(
        action: 'tap',
        args: {},
        timestamp: DateTime.now(),
        success: false,
        error: 'failed',
      );
      final json = entry.toJson();
      expect(json['error'], 'failed');
    });
  });
}
