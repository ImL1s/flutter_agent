library;

// Models
export 'src/models/widget_descriptor.dart';
export 'src/models/action_descriptor.dart';
export 'src/models/selector.dart';

// Core
export 'src/core/agent_core.dart';
export 'src/core/agent_config.dart';
export 'src/core/agent_state.dart';
export 'src/core/agent_callbacks.dart';
export 'src/core/consent_handler.dart';

// Components
export 'src/semantic/semantic_tree_walker.dart';
export 'src/semantic/node_resolver.dart';
export 'src/action/action_registry.dart';
export 'src/action/action_dispatcher.dart';
export 'src/action/built_in_actions.dart';
export 'src/action/semantics_action_executor.dart';
export 'src/llm/llm_client.dart';
export 'src/llm/openai_llm_client.dart';
export 'src/llm/streaming_llm_client.dart';
export 'src/llm/isolate_llm_client.dart';
export 'src/llm/conversation_history.dart';
export 'src/llm/retry_executor.dart';
export 'src/planner/planner.dart';
export 'src/planner/prompt_template.dart';
export 'src/executor/executor.dart';
export 'src/verifier/verifier.dart';
export 'src/audit/audit_log.dart';
export 'src/privacy/sensitive_data_masker.dart';
export 'src/macro/macro_recorder.dart';
export 'src/core/agent_widget.dart';
export 'src/debug/debug_overlay.dart';
