import '../models/widget_descriptor.dart';
import '../models/action_descriptor.dart';
import '../action/action_registry.dart';
import '../llm/llm_client.dart';
import '../llm/conversation_history.dart';
import '../llm/retry_executor.dart';
import 'prompt_template.dart';

/// Constructs LLM prompts from the current UI state and parses responses.
///
/// The [Planner] is responsible for:
/// 1. Formatting the [WidgetDescriptor] tree into a readable text prompt
/// 2. Attaching available tool schemas from [ActionRegistry]
/// 3. Sending the prompt to the [LLMClient]
/// 4. Returning parsed [ActionDescriptor] list
///
/// When [conversationHistory] is provided, the planner maintains multi-turn
/// context by appending user prompts and assistant tool calls to the history.
class Planner {
  final LLMClient llmClient;
  final ActionRegistry actionRegistry;

  /// Optional conversation history for multi-turn LLM interactions.
  final ConversationHistory? conversationHistory;

  /// Optional retry executor for resilient LLM calls.
  final RetryExecutor? retryExecutor;

  /// Optional prompt template for customizing LLM prompts.
  final PromptTemplate? promptTemplate;

  Planner({
    required this.llmClient,
    required this.actionRegistry,
    this.conversationHistory,
    this.retryExecutor,
    this.promptTemplate,
  });

  /// Build a prompt from the current UI state and task, send to LLM,
  /// and return the parsed action descriptors.
  Future<List<ActionDescriptor>> plan({
    required WidgetDescriptor uiState,
    required String task,
  }) async {
    final prompt = buildPrompt(uiState, task);
    final toolSchemas = actionRegistry.toToolSchemas();

    // Pass conversation history messages if available
    final messages = conversationHistory?.toMessages();

    // Call LLM (with retry if available)
    Future<List<ActionDescriptor>> doRequest() => llmClient.requestActions(
      prompt: prompt,
      toolSchemas: toolSchemas,
      messages: messages,
    );

    final actions = retryExecutor != null
        ? await retryExecutor!.execute(doRequest)
        : await doRequest();

    // Record this turn in history
    if (conversationHistory != null) {
      conversationHistory!.addUserMessage(prompt);
      if (actions.isNotEmpty) {
        conversationHistory!.addAssistantToolCalls(actions);
      }
    }

    return actions;
  }

  /// Build the text prompt from the UI state and task.
  ///
  /// Uses the [promptTemplate] if provided, otherwise falls back to
  /// the default format.
  String buildPrompt(WidgetDescriptor uiState, String task) {
    if (promptTemplate != null) {
      return promptTemplate!.format(
        uiState: uiState,
        task: task,
        actionNames: actionRegistry.registeredActions,
      );
    }
    return const DefaultPromptTemplate().format(
      uiState: uiState,
      task: task,
      actionNames: actionRegistry.registeredActions,
    );
  }
}
