import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudLlmService {
  final String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  final Dio _dio = Dio();

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
