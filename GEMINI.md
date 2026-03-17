# GEMINI.md

This file provides guidance to Gemini CLI and Google Antigravity when working with code in this repository.

## Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/core/agent_core_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Run the example app
cd example && flutter run
```

## Architecture

`flutter_agent` is a Flutter package that lets LLMs operate app UIs via the Semantics tree. The agent runs a **perceive → plan → execute → verify** loop in `AgentCore`.

### Pipeline

```
SemanticTreeWalker.capture() → WidgetDescriptor tree
    ↓
Planner.plan() → formats prompt + tool schemas → LLMClient.requestActions()
    ↓
Executor.executeAll() → ActionRegistry whitelist check → run actions → AuditLog
    ↓
Verifier.verify() → compare before/after WidgetDescriptor trees via JSON diff
    ↓
(unchanged? retry up to maxRetries, then error)
```

### Key Abstractions

- **`LLMClient`** (`lib/src/llm/llm_client.dart`) — Abstract interface. `OpenAILLMClient` is the provided implementation using Chat Completions with function-calling. `baseUrl` is configurable for proxies or local inference servers.
- **`ActionRegistry`** (`lib/src/action/action_registry.dart`) — Action whitelist. Only registered actions can be executed. Exports OpenAI-compatible tool schemas via `toToolSchemas()`.
- **`ActionDispatcher`** (`lib/src/action/action_dispatcher.dart`) — Resolves target nodes via `NodeResolver` + `Selector` before executing.
- **`SensitiveDataMasker`** (`lib/src/privacy/sensitive_data_masker.dart`) — Strips PII from `WidgetDescriptor` trees before LLM submission. Extensible via `extraPatterns`.
- **`ConversationHistory`** (`lib/src/llm/conversation_history.dart`) — Multi-turn OpenAI-format message buffer with FIFO eviction.
- **`RetryExecutor`** (`lib/src/llm/retry_executor.dart`) — Generic async retry with exponential backoff.

### Data Flow

`SemanticsNode` (Flutter runtime) → `WidgetDescriptor` (serializable tree with id/role/label/hint/value/actions/children) → text prompt → LLM → `ActionDescriptor` (parsed from OpenAI `tool_calls`) → `ActionRegistry.execute()` → `AuditEntry` recorded.

### Node Resolution

`Selector` supports `SelectorType.id`, `.label`, `.role`, `.key`. `NodeResolver.resolve()` does recursive DFS for first match; `resolveAll()` collects all matches.

### Testing

- Uses `mocktail` for mocking
- `SemanticTreeWalker` tests need widget test environment (accesses live `SemanticsNode`)
- E2E tests in `test/e2e/` for full pipeline scenarios
- Test structure mirrors `lib/src/` directory layout
