import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result of a lightweight scope check before RAG.
class CSharpScopeCheck {
  /// When true, run FTS + grounded answer prompt.
  final bool proceedWithRag;

  /// If non-null, show this to the user and do not run RAG.
  final String? blockMessage;

  const CSharpScopeCheck.proceed() : proceedWithRag = true, blockMessage = null;

  const CSharpScopeCheck.block(this.blockMessage) : proceedWithRag = false;
}

class CloudLlmService {
  final String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final Dio _dio = Dio();

  /// One non-streaming call: YES only if the user is asking about C# / .NET programming.
  /// Stops unrelated questions before retrieval, so the model is never used as a general chatbot.
  Future<CSharpScopeCheck> checkCSharpScope(String userQuery) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return const CSharpScopeCheck.block(
        'Error: API Key not found. Please check your .env file.',
      );
    }

    final trimmed = userQuery.trim();
    if (trimmed.isEmpty) {
      return const CSharpScopeCheck.block(
        'I only answer C# questions supported by the local knowledge base.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a strict classifier. Reply with exactly YES or NO, nothing else.\n'
                  'YES = the user message is primarily about C# programming, the .NET runtime or BCL, '
                  'ASP.NET Core in C#, or tooling used to write or debug C# code.\n'
                  'NO = general knowledge, other programming languages (unless comparing a tiny snippet to C#), '
                  'math, homework in other subjects, chitchat, recipes, politics, personal advice, or anything '
                  'not centered on C# / .NET development.',
            },
            {
              'role': 'user',
              'content': trimmed,
            },
          ],
          'temperature': 0,
          'max_tokens': 5,
          'stream': false,
        },
      );

      final data = response.data;
      final content = data?['choices']?[0]?['message']?['content'] as String?;
      final token = _firstWord(content ?? '');
      final upper = token.toUpperCase();
      final allowed = upper == 'YES' || upper == 'Y';

      if (allowed) {
        return const CSharpScopeCheck.proceed();
      }
      return const CSharpScopeCheck.block(
        'I only answer C# questions supported by the local knowledge base.',
      );
    } on DioException catch (e) {
      return CSharpScopeCheck.block('\n\n[Network Error: ${e.message}]');
    } catch (e) {
      return CSharpScopeCheck.block('\n\n[An unexpected error occurred.] ${e.toString()}');
    }
  }

  static String _firstWord(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    final i = t.indexOf(RegExp(r'\s'));
    return i < 0 ? t : t.substring(0, i);
  }

  /// Streams the response from Groq using Dio
  Stream<String> generateStream(String prompt) async* {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      yield "Error: API Key not found. Please check your .env file.";
      return;
    }

    try {
      // Make the POST request, explicitly asking for a Stream response
      final response = await _dio.post<ResponseBody>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          "model": "llama-3.1-8b-instant", // Groq's fast free model
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.1,
          "stream": true,
        },
      );

      final stream = response.data!.stream;

      // Decode the bytes and parse the Server-Sent Events (SSE)
      await for (final chunk in stream.cast<List<int>>().transform(
        utf8.decoder,
      )) {
        final lines = chunk.split('\n');

        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();

            if (dataStr == '[DONE]') return; // Stream finished gracefully

            if (dataStr.isNotEmpty) {
              try {
                final json = jsonDecode(dataStr);
                final content = json['choices'][0]['delta']['content'];
                if (content != null) {
                  yield content; // Push the word to the UI!
                }
              } catch (e) {
                // Ignore broken JSON chunks (normal in SSE)
              }
            }
          }
        }
      }
    } on DioException catch (e) {
      yield "\n\n[Network Error: ${e.message}]";
    } catch (e) {
      yield "\n\n[An unexpected error occurred.] ${e.toString()}";
    }
  }
}
