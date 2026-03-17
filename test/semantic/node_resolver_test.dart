import 'package:flutter_test/flutter_test.dart';
import 'package:ai_flutter_agent/ai_flutter_agent.dart';

void main() {
  // ─── Test data ──────────────────────────────────────────

  late WidgetDescriptor tree;

  setUp(() {
    tree = const WidgetDescriptor(
      id: '1',
      label: 'Root',
      role: 'generic',
      children: [
        WidgetDescriptor(
          id: '2',
          label: 'Header',
          role: 'header',
        ),
        WidgetDescriptor(
          id: '3',
          label: 'Content',
          role: 'generic',
          children: [
            WidgetDescriptor(
              id: '4',
              label: 'Login',
              role: 'button',
              actions: ['tap'],
            ),
            WidgetDescriptor(
              id: '5',
              label: 'Sign Up',
              role: 'button',
              actions: ['tap'],
            ),
            WidgetDescriptor(
              id: '6',
              label: 'Username',
              role: 'textField',
              hint: 'Enter username',
              actions: ['tap', 'setText'],
              children: [
                WidgetDescriptor(
                  id: '7',
                  label: 'Inner Label',
                  role: 'generic',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // ─── resolve() by ID ────────────────────────────────────

  group('resolve by ID', () {
    test('finds root node by id', () {
      final result = NodeResolver.resolve(tree, Selector.byId('1'));
      expect(result, isNotNull);
      expect(result!.id, '1');
    });

    test('finds nested node by id', () {
      final result = NodeResolver.resolve(tree, Selector.byId('4'));
      expect(result, isNotNull);
      expect(result!.label, 'Login');
    });

    test('finds deeply nested node by id', () {
      final result = NodeResolver.resolve(tree, Selector.byId('7'));
      expect(result, isNotNull);
      expect(result!.label, 'Inner Label');
    });

    test('returns null for non-existent id', () {
      final result = NodeResolver.resolve(tree, Selector.byId('999'));
      expect(result, isNull);
    });
  });

  // ─── resolve() by label ─────────────────────────────────

  group('resolve by label', () {
    test('finds node by exact label', () {
      final result = NodeResolver.resolve(
          tree, Selector.byLabel('Login'));
      expect(result, isNotNull);
      expect(result!.id, '4');
    });

    test('returns null for non-existent label', () {
      final result = NodeResolver.resolve(
          tree, Selector.byLabel('Does Not Exist'));
      expect(result, isNull);
    });
  });

  // ─── resolve() by role ──────────────────────────────────

  group('resolve by role', () {
    test('finds first node matching role', () {
      final result = NodeResolver.resolve(
          tree,
          const Selector(by: SelectorType.role, value: 'button'));
      expect(result, isNotNull);
      expect(result!.role, 'button');
    });

    test('returns null for non-existent role', () {
      final result = NodeResolver.resolve(
          tree,
          const Selector(by: SelectorType.role, value: 'slider'));
      expect(result, isNull);
    });
  });

  // ─── resolveAll() ───────────────────────────────────────

  group('resolveAll', () {
    test('returns all buttons', () {
      final results = NodeResolver.resolveAll(
          tree,
          const Selector(by: SelectorType.role, value: 'button'));
      expect(results, hasLength(2));
      expect(results.map((n) => n.label), containsAll(['Login', 'Sign Up']));
    });

    test('returns empty list when no match', () {
      final results = NodeResolver.resolveAll(
          tree,
          const Selector(by: SelectorType.role, value: 'slider'));
      expect(results, isEmpty);
    });

    test('returns single match as list', () {
      final results = NodeResolver.resolveAll(
          tree, Selector.byLabel('Username'));
      expect(results, hasLength(1));
      expect(results.first.id, '6');
    });
  });
}
