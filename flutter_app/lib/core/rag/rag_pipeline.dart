import 'package:flutter_app/core/services/cloud_llm_service.dart';
import 'package:flutter_app/core/services/context_builder.dart';
import 'package:flutter_app/core/services/fts_search_service.dart';

class RagPipeline {
  final CloudLlmService _cloudLlmService = CloudLlmService();

  Stream<String?> askQuestion(String userQuery) async* {
    // 1. LLM gate: only C# / .NET programming questions may use this app (no general chatbot).
    final scope = await _cloudLlmService.checkCSharpScope(userQuery);
    if (!scope.proceedWithRag) {
      yield scope.blockMessage;
      return;
    }

    // 2. Retrieve grounded snippets from the local SQLite DB
    final chunks = await FtsSearchService.searchContext(userQuery);

    // 3. In-scope C# question but no local hits: allow general knowledge for C#/.NET only (non-C# was blocked above).
    if (chunks.isEmpty) {
      yield 'No entries matched your local C# database. What follows is general C# / .NET knowledge, not from your offline snippets.\n\n';
      final fallback = ContextBuilder.buildUngroundedCSharpPrompt(userQuery);
      yield* _cloudLlmService.generateStream(fallback);
      return;
    }

    // 4. Stream a grounded answer from Groq
    final prompt = ContextBuilder.buildPrompt(userQuery, chunks);
    yield* _cloudLlmService.generateStream(prompt);
  }
}