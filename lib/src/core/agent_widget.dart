import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';

/// Widget wrapper that ensures semantics are enabled for the agent.
///
/// Wrap your app's root widget with [AgentOverlayWidget] to automatically
/// enable the semantics tree, which the agent needs to perceive the UI.
///
/// ```dart
/// runApp(
///   AgentOverlayWidget(
///     enabled: true,
///     child: MyApp(),
///   ),
/// );
/// ```
class AgentOverlayWidget extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Whether the agent overlay is active.
  final bool enabled;

  const AgentOverlayWidget({
    super.key,
    required this.child,
    this.enabled = true,
  });

  /// Find the nearest [AgentOverlayWidget] ancestor.
  static AgentOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<AgentOverlayState>();
  }

  @override
  State<AgentOverlayWidget> createState() => AgentOverlayState();
}

class AgentOverlayState extends State<AgentOverlayWidget> {
  SemanticsHandle? _semanticsHandle;

  /// Whether the overlay (and semantics) are currently active.
  bool get isActive => widget.enabled && _semanticsHandle != null;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _enableSemantics();
    }
  }

  @override
  void didUpdateWidget(AgentOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _enableSemantics();
    } else if (!widget.enabled && oldWidget.enabled) {
      _disableSemantics();
    }
  }

  @override
  void dispose() {
    _disableSemantics();
    super.dispose();
  }

  void _enableSemantics() {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  }

  void _disableSemantics() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
