# flutter_agent

A Flutter package that lets LLMs operate app UIs via the Semantics tree.

## Overview

`flutter_agent` provides a reusable framework for building LLM-powered UI agents in Flutter apps. The agent uses Flutter's Semantics tree to perceive the current UI state, sends structured prompts to an LLM via function-calling, and executes the resulting actions on the UI.

## Architecture

```
Flutter UI → Semantic Tree Walker → Planner (LLM Prompt) → LLM → Executor → UI
                                                                    ↓
                                                                 Verifier → Planner (retry)
```

## Getting Started

```dart
import 'package:flutter_agent/flutter_agent.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // See example/ for full usage
  runApp(MyApp());
}
```

## License

BSD 3-Clause. See [LICENSE](LICENSE).
