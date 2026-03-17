# Flutter Agent Framework Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a reusable Flutter package that lets LLMs operate app UIs through the Flutter Semantics tree and function-calling, following a perceive→plan→execute→verify agent loop.

**Architecture:** The package provides an `AgentCore` orchestrator that reads the live `SemanticsNode` tree into `WidgetDescriptor` data models, sends them as structured prompts to an LLM via an abstract `LLMClient`, receives `ActionDescriptor` responses, dispatches them through an `Executor` using `SemanticsOwner.performAction`, and validates results with a `Verifier`. All LLM interaction runs off the main UI thread via Dart async.

**Tech Stack:** Flutter (Dart), `flutter_test` / `mocktail` for testing, `http` for REST calls, `openai_dart` for OpenAI function-calling, BSD-3-Clause license.

---

## Proposed Changes

### 1. Project Scaffolding

#### [NEW] [pubspec.yaml](file:///d:/OtherProject/mine/flutter_agent/pubspec.yaml)

Create the Dart package manifest:

```yaml
name: flutter_agent
description: A Flutter package that lets LLMs operate app UIs via the Semantics tree.
version: 0.1.0
homepage: https://github.com/user/flutter_agent

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  openai_dart: ^0.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  flutter_lints: ^5.0.0
```

#### [NEW] [analysis_options.yaml](file:///d:/OtherProject/mine/flutter_agent/analysis_options.yaml)

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_fields: true
    avoid_print: false  # Allow print for debug/audit logging
```

#### [NEW] Directory structure

```
d:\OtherProject\mine\flutter_agent\
├── lib/
│   ├── flutter_agent.dart          # barrel export
│   └── src/
│       ├── models/
│       │   ├── widget_descriptor.dart
│       │   ├── action_descriptor.dart
│       │   └── selector.dart
│       ├── core/
│       │   ├── agent_core.dart
│       │   ├── agent_config.dart
│       │   └── agent_state.dart
│       ├── semantic/
│       │   └── semantic_tree_walker.dart
│       ├── action/
│       │   └── action_registry.dart
│       ├── llm/
│       │   ├── llm_client.dart        # abstract interface
│       │   └── openai_llm_client.dart  # OpenAI impl
│       ├── planner/
│       │   └── planner.dart
│       ├── executor/
│       │   └── executor.dart
│       ├── verifier/
│       │   └── verifier.dart
│       └── audit/
│           └── audit_log.dart
├── test/
│   ├── models/
│   │   ├── widget_descriptor_test.dart
│   │   ├── action_descriptor_test.dart
│   │   └── selector_test.dart
│   ├── semantic/
│   │   └── semantic_tree_walker_test.dart
│   ├── action/
│   │   └── action_registry_test.dart
│   ├── llm/
│   │   └── llm_client_test.dart
│   ├── planner/
│   │   └── planner_test.dart
│   ├── executor/
│   │   └── executor_test.dart
│   ├── verifier/
│   │   └── verifier_test.dart
│   ├── core/
│   │   └── agent_core_test.dart
│   └── audit/
│       └── audit_log_test.dart
├── example/
│   └── lib/
│       └── main.dart
└── docs/
    └── ...
```

---

### 2. Data Models

#### [NEW] [widget_descriptor.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/models/widget_descriptor.dart)

```dart
/// Represents a single node in the UI semantics tree.
class WidgetDescriptor {
  final String id;
  final String role;
  final String label;
  final String hint;
  final String value;
  final List<String> actions;
  final List<WidgetDescriptor> children;

  const WidgetDescriptor({
    required this.id,
    required this.role,
    required this.label,
    this.hint = '',
    this.value = '',
    this.actions = const [],
    this.children = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'label': label,
    if (hint.isNotEmpty) 'hint': hint,
    if (value.isNotEmpty) 'value': value,
    if (actions.isNotEmpty) 'actions': actions,
    if (children.isNotEmpty) 'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  String toString() => 'WidgetDescriptor(id=$id, role=$role, label=$label)';
}
```

#### [NEW] [action_descriptor.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/models/action_descriptor.dart)

```dart
/// Describes an action the LLM wants to execute on the UI.
class ActionDescriptor {
  final String actionName;
  final Map<String, dynamic> args;

  const ActionDescriptor({
    required this.actionName,
    this.args = const {},
  });

  factory ActionDescriptor.fromJson(Map<String, dynamic> json) {
    return ActionDescriptor(
      actionName: json['action'] as String,
      args: (json['args'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'action': actionName,
    'args': args,
  };

  @override
  String toString() => 'ActionDescriptor(action=$actionName, args=$args)';
}
```

#### [NEW] [selector.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/models/selector.dart)

```dart
/// Strategy for locating a target SemanticsNode.
enum SelectorType { id, label, role, key }

class Selector {
  final SelectorType by;
  final String value;

  const Selector({required this.by, required this.value});

  factory Selector.fromJson(Map<String, dynamic> json) {
    return Selector(
      by: SelectorType.values.firstWhere(
        (e) => e.name == json['by'],
        orElse: () => SelectorType.id,
      ),
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'by': by.name, 'value': value};
}
```

#### [NEW] [widget_descriptor_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/models/widget_descriptor_test.dart)
#### [NEW] [action_descriptor_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/models/action_descriptor_test.dart)
#### [NEW] [selector_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/models/selector_test.dart)

---

### 3. Semantic Tree Walker

#### [NEW] [semantic_tree_walker.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/semantic/semantic_tree_walker.dart)

Traverses Flutter's live `SemanticsNode` tree and produces `WidgetDescriptor` data:

```dart
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import '../models/widget_descriptor.dart';

class SemanticTreeWalker {
  /// Capture the current Semantics tree as a WidgetDescriptor tree.
  WidgetDescriptor? capture() {
    final binding = WidgetsBinding.instance;
    final semanticsOwner = binding.pipelineOwner.semanticsOwner;
    if (semanticsOwner == null) return null;
    final root = semanticsOwner.rootSemanticsNode;
    if (root == null) return null;
    return _walk(root);
  }

  WidgetDescriptor _walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    final actionNames = <String>[];
    for (final action in SemanticsAction.values) {
      if (data.hasAction(action)) {
        actionNames.add(action.name);
      }
    }

    return WidgetDescriptor(
      id: node.id.toString(),
      role: _inferRole(data),
      label: data.label,
      hint: data.hint,
      value: data.value,
      actions: actionNames,
      children: _getChildren(node).map(_walk).toList(),
    );
  }

  String _inferRole(SemanticsData data) {
    if (data.hasFlag(SemanticsFlag.isButton)) return 'button';
    if (data.hasFlag(SemanticsFlag.isTextField)) return 'textField';
    if (data.hasFlag(SemanticsFlag.isSlider)) return 'slider';
    if (data.hasFlag(SemanticsFlag.isLink)) return 'link';
    if (data.hasFlag(SemanticsFlag.isHeader)) return 'header';
    if (data.hasFlag(SemanticsFlag.isImage)) return 'image';
    if (data.hasFlag(SemanticsFlag.isChecked) || data.hasFlag(SemanticsFlag.hasCheckedState)) return 'checkbox';
    if (data.hasFlag(SemanticsFlag.isToggled) || data.hasFlag(SemanticsFlag.hasToggledState)) return 'toggle';
    return 'generic';
  }

  List<SemanticsNode> _getChildren(SemanticsNode node) {
    final children = <SemanticsNode>[];
    node.visitChildren((child) {
      children.add(child);
      return true;
    });
    return children;
  }
}
```

#### [NEW] [semantic_tree_walker_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/semantic/semantic_tree_walker_test.dart)

Uses a widget test with `Semantics`-annotated widgets to verify the walker.

---

### 4. Action Registry

#### [NEW] [action_registry.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/action/action_registry.dart)

```dart
typedef ActionFunction = Future<void> Function(Map<String, dynamic> args);

class ActionRegistry {
  final Map<String, ActionFunction> _actions = {};

  /// Register an action by name.
  void register(String name, ActionFunction fn) {
    _actions[name] = fn;
  }

  /// Unregister an action.
  void unregister(String name) {
    _actions.remove(name);
  }

  /// Check if an action is registered.
  bool has(String name) => _actions.containsKey(name);

  /// Execute a registered action. Throws if not found.
  Future<void> execute(String name, Map<String, dynamic> args) async {
    final action = _actions[name];
    if (action == null) {
      throw UnregisteredActionException(name);
    }
    await action(args);
  }

  /// List all registered action names.
  List<String> get registeredActions => _actions.keys.toList();

  /// Export action schemas for LLM function-calling.
  List<Map<String, dynamic>> toToolSchemas() {
    return registeredActions.map((name) => {
      'type': 'function',
      'function': {
        'name': name,
        'description': 'Perform the $name action on a UI element.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {'type': 'string', 'description': 'Target node ID'},
          },
          'required': ['id'],
        },
      },
    }).toList();
  }
}

class UnregisteredActionException implements Exception {
  final String actionName;
  UnregisteredActionException(this.actionName);
  @override
  String toString() => 'UnregisteredActionException: "$actionName" is not registered.';
}
```

#### [NEW] [action_registry_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/action/action_registry_test.dart)

---

### 5. LLM Client Abstraction

#### [NEW] [llm_client.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/llm/llm_client.dart)

```dart
import '../models/action_descriptor.dart';

/// Abstract interface for LLM communication.
abstract class LLMClient {
  /// Send a prompt with tool schemas and receive action descriptors.
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
  });
}
```

#### [NEW] [openai_llm_client.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/llm/openai_llm_client.dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_client.dart';
import '../models/action_descriptor.dart';

class OpenAILLMClient implements LLMClient {
  final String apiKey;
  final String model;
  final http.Client _httpClient;

  OpenAILLMClient({
    required this.apiKey,
    this.model = 'gpt-4o',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<ActionDescriptor>> requestActions({
    required String prompt,
    required List<Map<String, dynamic>> toolSchemas,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'You are a UI automation agent. Return tool calls to interact with the app UI.'},
        {'role': 'user', 'content': prompt},
      ],
      'tools': toolSchemas,
      'tool_choice': 'auto',
    });

    final response = await _httpClient.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw LLMException('OpenAI API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message = (json['choices'] as List).first['message'] as Map<String, dynamic>;
    final toolCalls = message['tool_calls'] as List?;

    if (toolCalls == null || toolCalls.isEmpty) return [];

    return toolCalls.map((tc) {
      final fn = tc['function'] as Map<String, dynamic>;
      return ActionDescriptor(
        actionName: fn['name'] as String,
        args: jsonDecode(fn['arguments'] as String) as Map<String, dynamic>,
      );
    }).toList();
  }
}

class LLMException implements Exception {
  final String message;
  LLMException(this.message);
  @override
  String toString() => 'LLMException: $message';
}
```

#### [NEW] [llm_client_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/llm/llm_client_test.dart)

Uses `mocktail` to mock `http.Client`, verifying request format and response parsing.

---

### 6. Planner

#### [NEW] [planner.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/planner/planner.dart)

```dart
import '../models/widget_descriptor.dart';
import '../models/action_descriptor.dart';
import '../action/action_registry.dart';
import '../llm/llm_client.dart';

class Planner {
  final LLMClient llmClient;
  final ActionRegistry actionRegistry;

  Planner({required this.llmClient, required this.actionRegistry});

  /// Build a prompt from the current UI state and task, send to LLM,
  /// and return parsed action descriptors.
  Future<List<ActionDescriptor>> plan({
    required WidgetDescriptor uiState,
    required String task,
  }) async {
    final prompt = _buildPrompt(uiState, task);
    final toolSchemas = actionRegistry.toToolSchemas();
    return llmClient.requestActions(prompt: prompt, toolSchemas: toolSchemas);
  }

  String _buildPrompt(WidgetDescriptor uiState, String task) {
    final uiJson = _formatTree(uiState, indent: 0);
    return '''
Current UI state:
$uiJson

Available actions: ${actionRegistry.registeredActions.join(', ')}

Task: $task

Respond with tool calls to accomplish the task.''';
  }

  String _formatTree(WidgetDescriptor node, {required int indent}) {
    final prefix = '  ' * indent;
    final buf = StringBuffer();
    buf.writeln('$prefix- [${node.role}] id=${node.id} label="${node.label}"'
        '${node.value.isNotEmpty ? ' value="${node.value}"' : ''}'
        '${node.actions.isNotEmpty ? ' actions=${node.actions}' : ''}');
    for (final child in node.children) {
      buf.write(_formatTree(child, indent: indent + 1));
    }
    return buf.toString();
  }
}
```

#### [NEW] [planner_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/planner/planner_test.dart)

---

### 7. Executor

#### [NEW] [executor.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/executor/executor.dart)

```dart
import '../models/action_descriptor.dart';
import '../action/action_registry.dart';
import '../audit/audit_log.dart';

class Executor {
  final ActionRegistry actionRegistry;
  final AuditLog auditLog;

  Executor({required this.actionRegistry, required this.auditLog});

  /// Execute a list of action descriptors sequentially.
  Future<List<ExecutionResult>> executeAll(List<ActionDescriptor> actions) async {
    final results = <ExecutionResult>[];
    for (final action in actions) {
      final result = await executeSingle(action);
      results.add(result);
      if (!result.success) break; // stop on first failure
    }
    return results;
  }

  Future<ExecutionResult> executeSingle(ActionDescriptor action) async {
    final timestamp = DateTime.now();
    try {
      if (!actionRegistry.has(action.actionName)) {
        final msg = 'Action "${action.actionName}" not in whitelist. Skipped.';
        auditLog.log(action: action.actionName, args: action.args, timestamp: timestamp, success: false, error: msg);
        return ExecutionResult(action: action, success: false, error: msg);
      }
      await actionRegistry.execute(action.actionName, action.args);
      auditLog.log(action: action.actionName, args: action.args, timestamp: timestamp, success: true);
      return ExecutionResult(action: action, success: true);
    } catch (e) {
      auditLog.log(action: action.actionName, args: action.args, timestamp: timestamp, success: false, error: e.toString());
      return ExecutionResult(action: action, success: false, error: e.toString());
    }
  }
}

class ExecutionResult {
  final ActionDescriptor action;
  final bool success;
  final String? error;

  ExecutionResult({required this.action, required this.success, this.error});
}
```

#### [NEW] [executor_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/executor/executor_test.dart)

---

### 8. Verifier

#### [NEW] [verifier.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/verifier/verifier.dart)

```dart
import '../models/widget_descriptor.dart';
import '../semantic/semantic_tree_walker.dart';

enum VerificationResult { success, changed, unchanged, error }

class Verifier {
  final SemanticTreeWalker treeWalker;

  Verifier({required this.treeWalker});

  /// Compare the UI state before and after action execution.
  VerificationResult verify({
    required WidgetDescriptor? before,
    required WidgetDescriptor? after,
  }) {
    if (before == null || after == null) return VerificationResult.error;

    final beforeJson = before.toJson().toString();
    final afterJson = after.toJson().toString();

    if (beforeJson == afterJson) {
      return VerificationResult.unchanged;
    }
    return VerificationResult.changed;
  }

  /// Capture current state and compare with previous.
  VerificationResult captureAndVerify({required WidgetDescriptor? previousState}) {
    final current = treeWalker.capture();
    return verify(before: previousState, after: current);
  }
}
```

#### [NEW] [verifier_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/verifier/verifier_test.dart)

---

### 9. AgentCore (Main Orchestrator)

#### [NEW] [agent_state.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/core/agent_state.dart)

```dart
enum AgentStatus { idle, running, paused, completed, error }

class AgentState {
  AgentStatus status;
  int stepCount;
  String? lastError;

  AgentState({this.status = AgentStatus.idle, this.stepCount = 0, this.lastError});
}
```

#### [NEW] [agent_core.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/core/agent_core.dart)

```dart
import '../models/widget_descriptor.dart';
import '../semantic/semantic_tree_walker.dart';
import '../planner/planner.dart';
import '../executor/executor.dart';
import '../verifier/verifier.dart';
import 'agent_state.dart';
import 'agent_config.dart';

class AgentCore {
  final AgentConfig config;
  final SemanticTreeWalker _treeWalker;
  final Planner _planner;
  final Executor _executor;
  final Verifier _verifier;
  final AgentState _state = AgentState();

  AgentCore({
    required this.config,
    required SemanticTreeWalker treeWalker,
    required Planner planner,
    required Executor executor,
    required Verifier verifier,
  })  : _treeWalker = treeWalker,
        _planner = planner,
        _executor = executor,
        _verifier = verifier;

  AgentState get state => _state;

  /// Run the agent loop for a given task.
  Future<void> run(String task) async {
    _state.status = AgentStatus.running;
    _state.stepCount = 0;

    try {
      for (var i = 0; i < config.maxSteps; i++) {
        if (_state.status != AgentStatus.running) break;

        // 1. Perceive
        final uiState = _treeWalker.capture();
        if (uiState == null) {
          _state.lastError = 'Failed to capture semantics tree';
          _state.status = AgentStatus.error;
          break;
        }

        // 2. Plan
        final actions = await _planner.plan(uiState: uiState, task: task);
        if (actions.isEmpty) {
          _state.status = AgentStatus.completed;
          break;
        }

        // 3. Execute
        final results = await _executor.executeAll(actions);

        // 4. Verify
        final postState = _treeWalker.capture();
        final verification = _verifier.verify(before: uiState, after: postState);

        _state.stepCount++;

        // If nothing changed and we had actions, might be stuck
        if (verification == VerificationResult.unchanged) {
          _state.lastError = 'UI unchanged after actions — possible stuck state';
          if (i >= config.maxRetries) {
            _state.status = AgentStatus.error;
            break;
          }
        }

        // Small delay between steps
        await Future.delayed(config.stepDelay);
      }

      if (_state.status == AgentStatus.running) {
        _state.status = AgentStatus.completed;
      }
    } catch (e) {
      _state.lastError = e.toString();
      _state.status = AgentStatus.error;
    }
  }

  void stop() {
    _state.status = AgentStatus.paused;
  }
}
```

#### [NEW] [agent_core_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/core/agent_core_test.dart)

---

### 10. AgentConfig

#### [NEW] [agent_config.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/core/agent_config.dart)

```dart
class AgentConfig {
  final int maxSteps;
  final int maxRetries;
  final Duration stepDelay;
  final bool debugMode;

  const AgentConfig({
    this.maxSteps = 20,
    this.maxRetries = 3,
    this.stepDelay = const Duration(milliseconds: 500),
    this.debugMode = false,
  });
}
```

---

### 11. Audit Log

#### [NEW] [audit_log.dart](file:///d:/OtherProject/mine/flutter_agent/lib/src/audit/audit_log.dart)

```dart
class AuditEntry {
  final String action;
  final Map<String, dynamic> args;
  final DateTime timestamp;
  final bool success;
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
}

class AuditLog {
  final List<AuditEntry> _entries = [];

  List<AuditEntry> get entries => List.unmodifiable(_entries);

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

  void clear() => _entries.clear();
}
```

#### [NEW] [audit_log_test.dart](file:///d:/OtherProject/mine/flutter_agent/test/audit/audit_log_test.dart)

---

### 12. Barrel Export

#### [NEW] [flutter_agent.dart](file:///d:/OtherProject/mine/flutter_agent/lib/flutter_agent.dart)

```dart
library flutter_agent;

// Models
export 'src/models/widget_descriptor.dart';
export 'src/models/action_descriptor.dart';
export 'src/models/selector.dart';

// Core
export 'src/core/agent_core.dart';
export 'src/core/agent_config.dart';
export 'src/core/agent_state.dart';

// Components
export 'src/semantic/semantic_tree_walker.dart';
export 'src/action/action_registry.dart';
export 'src/llm/llm_client.dart';
export 'src/llm/openai_llm_client.dart';
export 'src/planner/planner.dart';
export 'src/executor/executor.dart';
export 'src/verifier/verifier.dart';
export 'src/audit/audit_log.dart';
```

---

### 13. Example App

#### [NEW] [example/lib/main.dart](file:///d:/OtherProject/mine/flutter_agent/example/lib/main.dart)

Minimal demo showing how to integrate the agent with a simple form UI.

---

## Verification Plan

### Automated Tests

All commands run from `d:\OtherProject\mine\flutter_agent`:

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/models/widget_descriptor_test.dart
flutter test test/models/action_descriptor_test.dart
flutter test test/models/selector_test.dart
flutter test test/action/action_registry_test.dart
flutter test test/llm/llm_client_test.dart
flutter test test/planner/planner_test.dart
flutter test test/executor/executor_test.dart
flutter test test/verifier/verifier_test.dart
flutter test test/audit/audit_log_test.dart
flutter test test/core/agent_core_test.dart
```

### Test Coverage

Each task includes its own unit tests following TDD (red→green workflow):

| Component | Test File | Key Assertions |
|---|---|---|
| WidgetDescriptor | `test/models/widget_descriptor_test.dart` | `toJson()` roundtrip, nested children |
| ActionDescriptor | `test/models/action_descriptor_test.dart` | `fromJson()` parsing, empty args |
| Selector | `test/models/selector_test.dart` | All `SelectorType` variants |
| ActionRegistry | `test/action/action_registry_test.dart` | register/execute/unregister, whitelist enforcement |
| LLMClient (OpenAI) | `test/llm/llm_client_test.dart` | Mock HTTP, parse tool_calls, handle errors |
| Planner | `test/planner/planner_test.dart` | Prompt format, mock LLM returns correct actions |
| Executor | `test/executor/executor_test.dart` | Whitelist check, audit logging, stop-on-failure |
| Verifier | `test/verifier/verifier_test.dart` | changed/unchanged/error detection |
| AgentCore | `test/core/agent_core_test.dart` | Full loop mock, state transitions |
| AuditLog | `test/audit/audit_log_test.dart` | Entries recorded, clear works |

### Manual Verification

1. Run `flutter pub get` in the project root — should resolve all dependencies
2. Run `flutter analyze` — should report 0 issues
3. Run `flutter test` — all tests should pass
