// ignore_for_file: avoid_print
import 'dart:io';
/// Comprehensive E2E test suite for the Flutter Agent framework.
///
/// Usage:
///   LLM_BASE_URL=http://localhost:1234/v1 LLM_MODEL=my-model dart run test/e2e/comprehensive_e2e.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

final baseUrl = Platform.environment['LLM_BASE_URL'] ?? 'http://localhost:1234/v1';
final model = Platform.environment['LLM_MODEL'] ?? 'gpt-4o';

int _passed = 0;
int _failed = 0;
int _total = 0;

final _client = http.Client();

// ─── Tool Definitions ─────────────────────────────────────

final tapTool = {
  'type': 'function',
  'function': {
    'name': 'tap',
    'description': 'Tap a UI element to activate it.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
      },
      'required': ['id'],
    },
  },
};

final enterTextTool = {
  'type': 'function',
  'function': {
    'name': 'enterText',
    'description': 'Enter text into a text field.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
        'text': {'type': 'string', 'description': 'Text to type'},
      },
      'required': ['id', 'text'],
    },
  },
};

final scrollTool = {
  'type': 'function',
  'function': {
    'name': 'scroll',
    'description': 'Scroll a scrollable container.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Scrollable node ID'},
        'direction': {
          'type': 'string',
          'enum': ['up', 'down', 'left', 'right'],
          'description': 'Scroll direction',
        },
      },
      'required': ['id', 'direction'],
    },
  },
};

final setValueTool = {
  'type': 'function',
  'function': {
    'name': 'setValue',
    'description': 'Set the value of a slider or other adjustable widget.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
        'value': {'type': 'string', 'description': 'New value to set'},
      },
      'required': ['id', 'value'],
    },
  },
};

final toggleTool = {
  'type': 'function',
  'function': {
    'name': 'toggle',
    'description': 'Toggle a switch or checkbox.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
      },
      'required': ['id'],
    },
  },
};

final longPressTool = {
  'type': 'function',
  'function': {
    'name': 'longPress',
    'description': 'Long press on a UI element.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
      },
      'required': ['id'],
    },
  },
};

final dismissTool = {
  'type': 'function',
  'function': {
    'name': 'dismiss',
    'description': 'Dismiss a dialog or overlay.',
    'parameters': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'Target node ID'},
      },
      'required': ['id'],
    },
  },
};

List<Map<String, dynamic>> get allTools =>
    [tapTool, enterTextTool, scrollTool, setValueTool, toggleTool, longPressTool, dismissTool];

// ─── Helper ───────────────────────────────────────────────

Future<Map<String, dynamic>?> callLLM({
  required String prompt,
  required List<Map<String, dynamic>> tools,
  String systemPrompt =
      'You are a UI automation agent. '
      'Analyze the current UI state and return tool calls to interact with the app. '
      'Only use the provided tools. Be precise with node IDs. '
      'Return only tool calls, no explanation needed.',
}) async {
  final requestBody = <String, dynamic>{
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ],
  };
  if (tools.isNotEmpty) {
    requestBody['tools'] = tools;
    requestBody['tool_choice'] = 'auto';
  }

  final res = await _client.post(
    Uri.parse('$baseUrl/chat/completions'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  if (res.statusCode != 200) {
    print('   ✗ HTTP ${res.statusCode}: ${res.body}');
    return null;
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

List<Map<String, dynamic>> extractToolCalls(Map<String, dynamic> response) {
  final message =
      (response['choices'] as List).first['message'] as Map<String, dynamic>;
  final toolCalls = message['tool_calls'] as List?;
  if (toolCalls == null) return [];
  return toolCalls.map((tc) {
    final fn = tc['function'] as Map<String, dynamic>;
    final argsStr = fn['arguments'] as String? ?? '{}';
    Map<String, dynamic> args;
    try {
      args = jsonDecode(argsStr) as Map<String, dynamic>;
    } catch (_) {
      args = {};
    }
    return {'name': fn['name'] as String, 'args': args};
  }).toList();
}

void check(String name, bool condition) {
  _total++;
  if (condition) {
    _passed++;
    print('   ✓ $name');
  } else {
    _failed++;
    print('   ✗ FAIL: $name');
  }
}

// ─── Test Cases ───────────────────────────────────────────

/// Test 1: Simple single tap action
Future<void> test1_singleTap() async {
  print('\n── Test 1: Single tap action ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="App Screen"
  - [button] id=2 label="Login" actions=[tap]
  - [button] id=3 label="Sign Up" actions=[tap]

Available actions: tap

Task: Tap the Login button.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    check('action is tap', calls.first['name'] == 'tap');
    final args = calls.first['args'] as Map;
    check('targets node id=2 (Login)', args['id'] == '2');
  }
}

/// Test 2: Multi-step form filling (enterText + tap)
Future<void> test2_multiStepForm() async {
  print('\n── Test 2: Multi-step form filling ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Registration Form"
  - [textField] id=2 label="Username" hint="Enter username" value="" actions=[tap, setText]
  - [textField] id=3 label="Password" hint="Enter password" value="" actions=[tap, setText]
  - [button] id=4 label="Register" actions=[tap]

Available actions: tap, enterText

Task: Fill in "testuser" as username, "secret123" as password, then tap Register.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, enterTextTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned at least 1 tool call', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    // Model may return enterText directly, or tap first (to focus field),
    // or both — all are valid in a multi-turn agent loop
    final hasEnterTextOrTap = calls.any(
        (c) => c['name'] == 'enterText' || c['name'] == 'tap');
    check('uses enterText or tap action', hasEnterTextOrTap);
    // Verify args are well-formed
    final firstCall = calls.first;
    final args = firstCall['args'] as Map;
    check('first call has id argument', args.containsKey('id'));
    // If enterText is present, verify text arg
    final enterCalls = calls.where((c) => c['name'] == 'enterText');
    if (enterCalls.isNotEmpty) {
      check('enterText has text argument', (enterCalls.first['args'] as Map).containsKey('text'));
    }
  }
}

/// Test 3: Deep nested UI tree navigation
Future<void> test3_deepNestedTree() async {
  print('\n── Test 3: Deep nested UI tree ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Scaffold"
  - [header] id=2 label="Settings"
  - [generic] id=3 label="Content"
    - [generic] id=4 label="Account Section"
      - [generic] id=5 label="Profile Card"
        - [textField] id=6 label="Display Name" value="John" actions=[tap, setText]
        - [textField] id=7 label="Bio" value="" hint="Write about yourself" actions=[tap, setText]
      - [button] id=8 label="Save Changes" actions=[tap]
    - [generic] id=9 label="Notification Section"
      - [toggle] id=10 label="Push Notifications" value="off" actions=[tap]
      - [toggle] id=11 label="Email Notifications" value="on" actions=[tap]

Available actions: tap, enterText, toggle

Task: Change the display name to "Jane" and save the changes.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, enterTextTool, toggleTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    // Model may return enterText or tap (to focus field first) — both valid
    final targetIds = calls.map((c) => (c['args'] as Map)['id']).toSet();
    check('targets a node in the Profile Card area (id 6-8)',
        targetIds.any((id) => ['6', '7', '8'].contains(id)));
    // If enterText is used, verify content
    final enterCalls = calls.where((c) => c['name'] == 'enterText');
    if (enterCalls.isNotEmpty) {
      final args = enterCalls.first['args'] as Map;
      check('enterText targets Display Name (id=6)', args['id'] == '6');
      check('text contains "Jane"', (args['text'] ?? '').toString().contains('Jane'));
    } else {
      // If model returns tap first, that's valid (focus before type)
      check('returns tap as first step (valid multi-turn)', calls.first['name'] == 'tap');
    }
  }
}

/// Test 4: Slider value adjustment
Future<void> test4_sliderWidget() async {
  print('\n── Test 4: Slider widget ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Audio Settings"
  - [slider] id=2 label="Volume" value="30" hint="0 to 100" actions=[increase, decrease, setValue]
  - [slider] id=3 label="Bass" value="50" hint="0 to 100" actions=[increase, decrease, setValue]
  - [button] id=4 label="Apply" actions=[tap]

Available actions: setValue, tap

Task: Set the volume to 80.''';

  final res = await callLLM(prompt: prompt, tools: [setValueTool, tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final hasSetValue = calls.any((c) => c['name'] == 'setValue');
    check('uses setValue action', hasSetValue);
    if (hasSetValue) {
      final setCall = calls.firstWhere((c) => c['name'] == 'setValue');
      final args = setCall['args'] as Map;
      check('targets Volume slider (id=2)', args['id'] == '2');
      check('sets value to 80', args['value']?.toString() == '80');
    }
  }
}

/// Test 5: Checkbox / Toggle interactions
Future<void> test5_checkboxToggle() async {
  print('\n── Test 5: Checkbox and toggle ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Privacy Settings"
  - [checkbox] id=2 label="Accept Terms of Service" value="unchecked" actions=[tap]
  - [checkbox] id=3 label="Receive Marketing Emails" value="unchecked" actions=[tap]
  - [toggle] id=4 label="Dark Mode" value="off" actions=[tap]
  - [button] id=5 label="Continue" actions=[tap]

Available actions: tap, toggle

Task: Accept the Terms of Service and enable Dark Mode, then tap Continue.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, toggleTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    // Should include tapping/toggling on Terms (id=2) and Dark Mode (id=4)
    final targetIds = calls.map((c) => (c['args'] as Map)['id']).toSet();
    check('targets Terms checkbox (id=2)', targetIds.contains('2'));
  }
}

/// Test 6: Scroll + tap on hidden content
Future<void> test6_scrollToFind() async {
  print('\n── Test 6: Scroll to find hidden items ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Product List"
  - [generic] id=2 label="Scrollable List" actions=[scrollUp, scrollDown]
    - [generic] id=3 label="Item 1 - Laptop" actions=[tap]
    - [generic] id=4 label="Item 2 - Phone" actions=[tap]
    - [generic] id=5 label="Item 3 - Tablet" actions=[tap]
  - [generic] id=6 label="More items below (scroll down to see)"

Available actions: tap, scroll

Task: The item "Headphones" is not visible. Scroll down to find it.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, scrollTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final hasScroll = calls.any((c) => c['name'] == 'scroll');
    check('uses scroll action', hasScroll);
    if (hasScroll) {
      final scrollCall = calls.firstWhere((c) => c['name'] == 'scroll');
      final args = scrollCall['args'] as Map;
      check('scrolls down direction', args['direction'] == 'down');
    }
  }
}

/// Test 7: "No action needed" — task already done
Future<void> test7_noActionNeeded() async {
  print('\n── Test 7: No action needed ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Success Screen"
  - [image] id=2 label="Checkmark Icon"
  - [header] id=3 label="Payment Successful!"
  - [generic] id=4 label="Your order #12345 has been confirmed."
  - [button] id=5 label="Go Home" actions=[tap]

Available actions: tap

Task: The payment has already been completed. No further action is needed.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  // Model should either return no tool calls, or at most a contextual action
  check('returns 0 or minimal actions (task already done)', calls.length <= 1);
}

/// Test 8: Long press context menu
Future<void> test8_longPress() async {
  print('\n── Test 8: Long press action ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Message List"
  - [generic] id=2 label="Message from Alice: Hey, how are you?" actions=[tap, longPress]
  - [generic] id=3 label="Message from Bob: Meeting at 3pm" actions=[tap, longPress]
  - [generic] id=4 label="Message from Carol: Check this out!" actions=[tap, longPress]

Available actions: tap, longPress

Task: Long press on Bob's message to open the context menu.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, longPressTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final hasLongPress = calls.any((c) => c['name'] == 'longPress');
    check('uses longPress action', hasLongPress);
    if (hasLongPress) {
      final lpCall = calls.firstWhere((c) => c['name'] == 'longPress');
      final args = lpCall['args'] as Map;
      check('targets Bob message (id=3)', args['id'] == '3');
    }
  }
}

/// Test 9: Dialog dismiss interaction
Future<void> test9_dialogDismiss() async {
  print('\n── Test 9: Dialog dismiss ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Main Screen" 
- [generic] id=2 label="Alert Dialog"
  - [header] id=3 label="Delete Confirmation"
  - [generic] id=4 label="Are you sure you want to delete this item? This cannot be undone."
  - [button] id=5 label="Cancel" actions=[tap]
  - [button] id=6 label="Delete" actions=[tap]

Available actions: tap, dismiss

Task: Cancel the deletion — do NOT delete the item.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, dismissTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final firstCall = calls.first;
    final args = firstCall['args'] as Map;
    // Must NOT tap Delete (id=6)
    final tapsDelete = calls.any(
        (c) => c['name'] == 'tap' && (c['args'] as Map)['id'] == '6');
    check('does NOT tap Delete (id=6)', !tapsDelete);
    // Valid strategies: tap Cancel (id=5), dismiss dialog, or dismiss any node
    final validCancel = firstCall['name'] == 'dismiss' ||
        (firstCall['name'] == 'tap' && args['id'] == '5');
    check('cancels via tap Cancel or dismiss', validCancel);
  }
}

/// Test 10: Multi-turn agent loop simulation
Future<void> test10_multiTurnLoop() async {
  print('\n── Test 10: Multi-turn agent loop (2 rounds) ──');

  // Round 1: UI before action
  final prompt1 = '''Current UI state:
- [generic] id=1 label="Login Form"
  - [textField] id=2 label="Email" value="" hint="Enter email" actions=[tap, setText]
  - [textField] id=3 label="Password" value="" hint="Enter password" actions=[tap, setText]
  - [button] id=4 label="Sign In" actions=[tap]

Available actions: tap, enterText

Task: Log in with email "test@example.com" and password "pass123".''';

  final res1 = await callLLM(prompt: prompt1, tools: [tapTool, enterTextTool]);
  if (res1 == null) { check('Round 1: got response', false); return; }
  final calls1 = extractToolCalls(res1);
  check('Round 1: returned actions', calls1.isNotEmpty);

  // Round 2: UI after entering email (simulated state change)
  final prompt2 = '''Current UI state:
- [generic] id=1 label="Login Form"
  - [textField] id=2 label="Email" value="test@example.com" actions=[tap, setText]
  - [textField] id=3 label="Password" value="" hint="Enter password" actions=[tap, setText]
  - [button] id=4 label="Sign In" actions=[tap]

Available actions: tap, enterText

Task: Log in with email "test@example.com" and password "pass123".
Note: Email has already been entered. Continue with the remaining steps.''';

  final res2 = await callLLM(prompt: prompt2, tools: [tapTool, enterTextTool]);
  if (res2 == null) { check('Round 2: got response', false); return; }
  final calls2 = extractToolCalls(res2);
  check('Round 2: returned actions', calls2.isNotEmpty);

  if (calls2.isNotEmpty) {
    // Round 2 should focus on password or Sign In, NOT re-enter email
    final targets2 = calls2.map((c) => (c['args'] as Map)['id']).toSet();
    check('Round 2: moves forward (not re-entering email)', !targets2.contains('2') || calls2.any((c) => c['name'] == 'enterText' && (c['args'] as Map)['id'] == '3'));
  }
}

/// Test 11: Complex real-world e-commerce flow
Future<void> test11_ecommerceFlow() async {
  print('\n── Test 11: E-commerce product page ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Product Detail"
  - [image] id=2 label="Product Photo - Blue T-Shirt"
  - [header] id=3 label="Blue T-Shirt"
  - [generic] id=4 label="Price: \$29.99"
  - [generic] id=5 label="Size Selection"
    - [button] id=6 label="S" actions=[tap]
    - [button] id=7 label="M" actions=[tap]
    - [button] id=8 label="L" actions=[tap]
    - [button] id=9 label="XL" actions=[tap]
  - [generic] id=10 label="Quantity"
    - [button] id=11 label="-" actions=[tap]
    - [generic] id=12 label="1"
    - [button] id=13 label="+" actions=[tap]
  - [button] id=14 label="Add to Cart" actions=[tap]
  - [button] id=15 label="Buy Now" actions=[tap]

Available actions: tap

Task: Select size L and add the item to cart.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final ids = calls.map((c) => (c['args'] as Map)['id']).toList();
    check('selects size L (id=8)', ids.contains('8'));
  }
}

/// Test 12: Disambiguation — similar labels
Future<void> test12_disambiguation() async {
  print('\n── Test 12: Disambiguation — similar labels ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Settings"
  - [button] id=2 label="Delete Account" actions=[tap]
  - [button] id=3 label="Delete Cache" actions=[tap]
  - [button] id=4 label="Delete Downloads" actions=[tap]

Available actions: tap

Task: Delete the cache only. Do NOT delete the account.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final args = calls.first['args'] as Map;
    check('targets Delete Cache (id=3), NOT Delete Account (id=2)', args['id'] == '3');
  }
}

/// Test 13: Multiple tool types in one response
Future<void> test13_mixedToolCalls() async {
  print('\n── Test 13: Mixed tool types (enterText + toggle + tap) ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="New Post"
  - [textField] id=2 label="Title" value="" actions=[tap, setText]
  - [textField] id=3 label="Body" value="" hint="Write your post..." actions=[tap, setText]
  - [toggle] id=4 label="Publish Immediately" value="off" actions=[tap]
  - [button] id=5 label="Post" actions=[tap]

Available actions: tap, enterText, toggle

Task: Create a post titled "Hello World", enable Publish Immediately, and tap Post.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool, enterTextTool, toggleTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final actionNames = calls.map((c) => c['name']).toSet();
    // Model should use at least one of the provided tool types
    final usesKnownAction = actionNames.any(
        (n) => ['enterText', 'tap', 'toggle'].contains(n));
    check('uses known actions (enterText/tap/toggle)', usesKnownAction);
    // Verify args are well-formed
    for (final call in calls) {
      final args = call['args'] as Map;
      check('call ${call['name']} has id', args.containsKey('id'));
    }
  }
}

/// Test 14: Planner prompt construction — verify format is LLM-parseable
Future<void> test14_promptParseability() async {
  print('\n── Test 14: Prompt format parseability ──');
  // Send a deliberately complex, indented UI tree and verify model can parse it
  final prompt = '''Current UI state:
- [generic] id=1 label="Root"
  - [generic] id=2 label="TabBar"
    - [button] id=3 label="Home" actions=[tap]
    - [button] id=4 label="Search" actions=[tap]
    - [button] id=5 label="Profile" actions=[tap]
  - [generic] id=6 label="TabView"
    - [generic] id=7 label="Home Content"
      - [generic] id=8 label="Featured"
        - [generic] id=9 label="Card 1"
          - [image] id=10 label="Banner"
          - [button] id=11 label="Learn More" actions=[tap]
        - [generic] id=12 label="Card 2"
          - [image] id=13 label="Promo"
          - [button] id=14 label="Shop Now" actions=[tap]
      - [generic] id=15 label="Recent Activity"
        - [generic] id=16 label="You have 3 notifications" actions=[tap]

Available actions: tap

Task: Navigate to the Profile tab.''';

  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  check('returned tool calls', calls.isNotEmpty);
  if (calls.isNotEmpty) {
    final args = calls.first['args'] as Map;
    check('correctly identifies Profile tab (id=5) from deep tree', args['id'] == '5');
  }
}

/// Test 15: Tool schema completeness — only use provided tools
Future<void> test15_toolConstraint() async {
  print('\n── Test 15: Tool constraint — only use provided tools ──');
  final prompt = '''Current UI state:
- [generic] id=1 label="Photo Gallery"
  - [image] id=2 label="Photo 1" actions=[tap, longPress]
  - [image] id=3 label="Photo 2" actions=[tap, longPress]
  - [button] id=4 label="Upload New" actions=[tap]

Available actions: tap

Task: Delete Photo 1.
Note: There is no delete action available in the tools. You should explain this limitation.''';

  // Only provide tap tool — no delete tool
  final res = await callLLM(prompt: prompt, tools: [tapTool]);
  if (res == null) { check('got response', false); return; }

  final calls = extractToolCalls(res);
  // Model should either return no calls (recognizes limitation),
  // or only use provided tools (tap) — never hallucinate a delete tool
  if (calls.isEmpty) {
    check('returns no calls (recognizes no delete tool)', true);
  } else {
    // Even non-tap is acceptable if model tries longPress which was in UI actions
    check('does not hallucinate a delete tool', 
        calls.every((c) => ['tap', 'longPress'].contains(c['name'])));
  }
}

// ─── Main ─────────────────────────────────────────────────

void main() async {
  print('═══════════════════════════════════════════════════════════════');
  print(' Flutter Agent — Comprehensive E2E Test Suite');
  print(' Model: $model');
  print(' Endpoint: $baseUrl');
  print('═══════════════════════════════════════════════════════════════');

  // Verify connection
  try {
    final modelsRes = await _client.get(Uri.parse('$baseUrl/models'));
    if (modelsRes.statusCode != 200) {
      print('\n✗ Cannot connect to model server at $baseUrl');
      return;
    }
    print('\n✓ Connected to model server\n');
  } catch (e) {
    print('\n✗ Connection failed: $e');
    return;
  }

  // Run all tests
  await test1_singleTap();
  await test2_multiStepForm();
  await test3_deepNestedTree();
  await test4_sliderWidget();
  await test5_checkboxToggle();
  await test6_scrollToFind();
  await test7_noActionNeeded();
  await test8_longPress();
  await test9_dialogDismiss();
  await test10_multiTurnLoop();
  await test11_ecommerceFlow();
  await test12_disambiguation();
  await test13_mixedToolCalls();
  await test14_promptParseability();
  await test15_toolConstraint();

  // Summary
  print('\n═══════════════════════════════════════════════════════════════');
  print(' Results: $_passed/$_total passed, $_failed failed');
  print('═══════════════════════════════════════════════════════════════');

  _client.close();
}
