import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

void main() {
  group('DebugLogStream', () {
    test('stream emits events', () async {
      final debugLog = DebugLogStream();
      final events = <DebugEvent>[];
      final sub = debugLog.stream.listen(events.add);

      debugLog.stepStarted(1, 10);
      debugLog.actionExecuted('tap', true);
      debugLog.completed('completed');

      // Let microtasks fire
      await Future.delayed(Duration.zero);

      expect(events, hasLength(3));
      expect(events[0].type, DebugEventType.stepStart);
      expect(events[1].type, DebugEventType.actionSuccess);
      expect(events[2].type, DebugEventType.completed);

      await sub.cancel();
      debugLog.dispose();
    });

    test('emits error events', () async {
      final debugLog = DebugLogStream();
      final events = <DebugEvent>[];
      final sub = debugLog.stream.listen(events.add);

      debugLog.error('Something broke');

      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, DebugEventType.error);
      expect(events.first.message, contains('Something broke'));

      await sub.cancel();
      debugLog.dispose();
    });

    test('DebugEvent toString has correct format', () {
      final event = DebugEvent(
        type: DebugEventType.actionFailure,
        message: 'tap: FAILED',
        timestamp: DateTime(2026, 1, 1),
      );

      expect(event.toString(), contains('actionFailure'));
      expect(event.toString(), contains('tap: FAILED'));
    });
  });
}
