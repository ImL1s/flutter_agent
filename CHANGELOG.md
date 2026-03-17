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
