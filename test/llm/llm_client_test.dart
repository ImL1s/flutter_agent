import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ai_flutter_agent/src/llm/openai_llm_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late OpenAILLMClient llmClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    llmClient = OpenAILLMClient(
      apiKey: 'test-key',
      model: 'gpt-4o',
      httpClient: mockClient,
    );
  });

  group('OpenAILLMClient', () {
    test('sends correct request format', () async {
      final responseBody = jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'tool_calls': [
                {
                  'id': 'call_1',
                  'type': 'function',
                  'function': {
                    'name': 'tap',
                    'arguments': '{"id": "42"}',
                  },
                },
              ],
            },
          },
        ],
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response(responseBody, 200));

      final tools = [
        {
          'type': 'function',
          'function': {
            'name': 'tap',
            'parameters': {'type': 'object', 'properties': {}},
          },
        },
      ];

      final actions = await llmClient.requestActions(
        prompt: 'Tap the button',
        toolSchemas: tools,
      );

      // Verify the request was made
      final captured = verify(() => mockClient.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;

      final uri = captured[0] as Uri;
      expect(uri.toString(), contains('chat/completions'));

      final headers = captured[1] as Map;
      expect(headers['Authorization'], 'Bearer test-key');

      final body = jsonDecode(captured[2] as String) as Map;
      expect(body['model'], 'gpt-4o');

      // Verify parsed actions
      expect(actions, hasLength(1));
      expect(actions.first.actionName, 'tap');
      expect(actions.first.args['id'], '42');
    });

    test('returns empty list when no tool_calls', () async {
      final responseBody = jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'No action needed.',
            },
          },
        ],
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response(responseBody, 200));

      final actions = await llmClient.requestActions(
        prompt: 'test',
        toolSchemas: [],
      );

      expect(actions, isEmpty);
    });

    test('parses multiple tool calls', () async {
      final responseBody = jsonEncode({
        'choices': [
          {
            'message': {
              'tool_calls': [
                {
                  'function': {
                    'name': 'tap',
                    'arguments': '{"id": "1"}',
                  },
                },
                {
                  'function': {
                    'name': 'enterText',
                    'arguments': '{"id": "2", "text": "hello"}',
                  },
                },
              ],
            },
          },
        ],
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response(responseBody, 200));

      final actions = await llmClient.requestActions(
        prompt: 'test',
        toolSchemas: [],
      );

      expect(actions, hasLength(2));
      expect(actions[0].actionName, 'tap');
      expect(actions[1].actionName, 'enterText');
      expect(actions[1].args['text'], 'hello');
    });

    test('throws LLMException on API error', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response('{"error": "bad"}', 500));

      expect(
        () => llmClient.requestActions(prompt: 'test', toolSchemas: []),
        throwsA(isA<LLMException>()),
      );
    });

    test('handles malformed arguments gracefully', () async {
      final responseBody = jsonEncode({
        'choices': [
          {
            'message': {
              'tool_calls': [
                {
                  'function': {
                    'name': 'tap',
                    'arguments': 'not-valid-json',
                  },
                },
              ],
            },
          },
        ],
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response(responseBody, 200));

      final actions = await llmClient.requestActions(
        prompt: 'test',
        toolSchemas: [],
      );

      expect(actions, hasLength(1));
      expect(actions.first.actionName, 'tap');
      expect(actions.first.args, isEmpty); // graceful fallback
    });
  });
}
