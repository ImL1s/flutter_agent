# AGENTS.md

This file provides guidance to AI coding agents (Codex CLI, etc.) when working with code in this repository.

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

- **`LLMClient`** — Abstract interface for LLM communication. `OpenAILLMClient` implements it via HTTP with function-calling. `baseUrl` is configurable for proxies/local servers.
- **`ActionRegistry`** — Whitelist of allowed actions. Unregistered actions are rejected. Exports OpenAI-compatible tool schemas via `toToolSchemas()`.
- **`ActionDispatcher`** — Resolves target nodes via `NodeResolver` + `Selector` before executing through the registry.
- **`SensitiveDataMasker`** — Strips PII (emails, phones, credit cards) from `WidgetDescriptor` trees before sending to LLM. Extensible via `extraPatterns`.
- **`ConversationHistory`** — Multi-turn OpenAI-format message buffer with FIFO eviction.
- **`RetryExecutor`** — Generic async retry with exponential backoff.

### Data Flow

`SemanticsNode` → `WidgetDescriptor` → text prompt → LLM → `ActionDescriptor` → `ActionRegistry.execute()` → `AuditEntry`.

### Node Resolution

`Selector` supports finding nodes by `id`, `label`, `role`, or `key`. `NodeResolver` uses recursive DFS.

### Testing

Uses `mocktail` for mocking. `SemanticTreeWalker` requires widget test environment. E2E tests in `test/e2e/`. Test structure mirrors `lib/src/`.

## Dependencies

- `http: ^1.2.0` — HTTP client for LLM API calls
- `mocktail: ^1.0.0` — Test mocking
- `flutter_lints: ^5.0.0` — Lint rules

## Conventions

- Barrel export at `lib/flutter_agent.dart` — all public API exported here
- `AgentConfig` gathered in one class with `copyWith` support
- All executor actions logged to `AuditLog` (success and failure)
- `WidgetDescriptor.toJson()` used for deterministic comparison in `Verifier`
