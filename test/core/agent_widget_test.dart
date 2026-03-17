import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

void main() {
  group('AgentOverlayWidget', () {
    testWidgets('wraps child widget', (tester) async {
      await tester.pumpWidget(
        const AgentOverlayWidget(
          child: Text('Hello', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('reports isActive=true when enabled', (tester) async {
      await tester.pumpWidget(
        const AgentOverlayWidget(
          enabled: true,
          child: SizedBox(),
        ),
      );

      final state = tester.state<AgentOverlayState>(
        find.byType(AgentOverlayWidget),
      );
      expect(state.isActive, isTrue);

      // Properly dispose to avoid scheduler exception
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reports isActive=false when disabled', (tester) async {
      await tester.pumpWidget(
        const AgentOverlayWidget(
          enabled: false,
          child: SizedBox(),
        ),
      );

      final state = tester.state<AgentOverlayState>(
        find.byType(AgentOverlayWidget),
      );
      expect(state.isActive, isFalse);
    });
  });
}
