# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

`ai_flutter_agent` is a Flutter package that lets LLMs operate app UIs via the Semantics tree. The core loop is **perceive → plan → execute → verify**, orchestrated by `AgentCore`.

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

- **`LLMClient`** — Abstract interface for LLM communication. `OpenAILLMClient` is the HTTP-based implementation using Chat Completions with function-calling. Supports custom `baseUrl` for proxies/local servers.
- **`ActionRegistry`** — Whitelist of allowed actions. Actions not registered here are rejected by the Executor. Exports OpenAI-compatible tool schemas via `toToolSchemas()`.
- **`ActionDispatcher`** — Higher-level dispatch that resolves target nodes via `NodeResolver` + `Selector` before executing through the registry.
- **`SensitiveDataMasker`** — Strips PII (emails, phone numbers, credit cards) from `WidgetDescriptor` trees before sending to the LLM. Supports custom regex patterns.
- **`ConversationHistory`** — Manages multi-turn OpenAI-format messages with FIFO eviction.
- **`RetryExecutor`** — Generic async retry with exponential backoff, used for LLM calls.

### Data Flow

`SemanticsNode` (Flutter) → `WidgetDescriptor` (serializable tree) → text prompt → LLM → `ActionDescriptor` (parsed from tool_calls) → `ActionRegistry.execute()` → `AuditEntry` logged.

### Node Resolution

`Selector` supports finding nodes by `id`, `label`, `role`, or `key`. `NodeResolver` does recursive DFS on the `WidgetDescriptor` tree (`resolve` for first match, `resolveAll` for all).

### Testing

All tests use `mocktail` for mocking. The `SemanticTreeWalker` requires a widget test environment since it accesses live `SemanticsNode` trees. E2E tests exist in `test/e2e/` for full-loop scenarios.
