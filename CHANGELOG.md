## 0.1.3

- **Fix:** Resolve "UI unchanged" error when toggling `Switch`, `Checkbox`, and other stateful widgets — `WidgetDescriptor` now captures `isToggled`, `isChecked`, and `isEnabled` states from `SemanticsFlag`.
- **Fix:** `setText` action now automatically taps the target `TextField` first to ensure focus, fixing silent failures on unfocused text inputs.
- **Improve:** `SemanticTreeWalker` explicitly advertises `setText` action for all `TextField` nodes.
- **Improve:** `AgentCore` injects execution feedback into conversation history for better multi-turn LLM reasoning.
- **Improve:** Post-action delay increased for reliable UI state settling before verification.
- **Docs:** README rewrite with demo video and explanation of Semantics-tree approach vs screenshot-coordinate automation.
- **Example:** Added 5 demo apps (Counter, Todo, Chat, Form, Shopping) in `example/` for testing all action types.

## 0.1.2

- **Docs:** Updated `README.md` installation instructions to use `flutter pub add` instead of `git`, and added pub.dev version badge.

## 0.1.1

- **Docs:** Major README overhaul with new framework icon, badges, accurate Quick Start guide, and categorized feature list.
- **Docs:** Fixed GitHub URLs in `pubspec.yaml` and `README.md` to point to correct repository for pub.dev scoring.
- **Chore:** Resolved 39 static analysis warnings (`prefer_const_constructors`, unused imports).
- **Security:** Replaced hardcoded localhost IPs in E2E tests with environment variables.

## 0.1.0
Initial release with 25 features across 5 phases.

### Core
- Agent loop: perceive → plan → execute → verify (`AgentCore`)
- Semantic tree walker (`SemanticTreeWalker`)
- Action registry with whitelist enforcement (`ActionRegistry`)
- LLM client abstraction with OpenAI implementation (`LLMClient`, `OpenAILLMClient`)
- Audit logging (`AuditLog`)

### Advanced
- Multi-turn conversation history (`ConversationHistory`)
- Privacy-aware data masking (`SensitiveDataMasker`)
- Resilient LLM calls with retry (`RetryExecutor`)
- Smart executor with node resolution (`ActionDispatcher`)
- Agent event callbacks (`AgentCallbacks`)
- Streaming LLM support (`StreamingLLMClient`)

### Safety
- User consent gate (`ConsentHandler`)
- Per-action confirmation hook
- Action timeout enforcement
- Isolate LLM execution (`IsolateLLMClient`)

### Production
- Customizable prompt templates (`PromptTemplate`, `CustomPromptTemplate`)
- Built-in actions: tap, longPress, scroll, setText, focus, dismiss (`BuiltInActions`)
- Semantics action executor (`SemanticsActionExecutor`)
- Structured diff verification (`VerificationDetail`)
- Macro recording & replay (`MacroRecorder`, `Macro`, `MacroStore`)
- Agent widget wrapper (`AgentOverlayWidget`)
- Debug event stream (`DebugLogStream`)
