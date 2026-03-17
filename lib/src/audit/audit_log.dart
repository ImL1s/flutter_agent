/// Audit log entry recording a single agent action.
class AuditEntry {
  /// Action name that was executed.
  final String action;

  /// Arguments passed to the action.
  final Map<String, dynamic> args;

  /// When the action was executed.
  final DateTime timestamp;

  /// Whether execution succeeded.
  final bool success;

  /// Error message if execution failed.
  final String? error;

  AuditEntry({
    required this.action,
    required this.args,
    required this.timestamp,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'args': args,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        if (error != null) 'error': error,
      };

  @override
  String toString() =>
      'AuditEntry(action=$action, success=$success, time=${timestamp.toIso8601String()})';
}

/// Records all actions executed by the agent for auditing and debugging.
///
/// Every action the [Executor] processes is logged here, including
/// failures and skipped actions (whitelist violations).
class AuditLog {
  final List<AuditEntry> _entries = [];

  /// Read-only view of all log entries.
  List<AuditEntry> get entries => List.unmodifiable(_entries);

  /// Number of recorded entries.
  int get length => _entries.length;

  /// Add a log entry.
  void log({
    required String action,
    required Map<String, dynamic> args,
    required DateTime timestamp,
    required bool success,
    String? error,
  }) {
    _entries.add(AuditEntry(
      action: action,
      args: args,
      timestamp: timestamp,
      success: success,
      error: error,
    ));
  }

  /// Get only failed entries.
  List<AuditEntry> get failures =>
      _entries.where((e) => !e.success).toList();

  /// Clear all entries.
  void clear() => _entries.clear();
}
