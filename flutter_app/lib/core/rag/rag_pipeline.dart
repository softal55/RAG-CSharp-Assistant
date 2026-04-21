import 'package:flutter_app/core/services/cloud_llm_service.dart';
import 'package:flutter_app/core/services/context_builder.dart';
import 'package:flutter_app/core/services/fts_search_service.dart';

class RagPipeline {
  final CloudLlmService _cloudLlmService = CloudLlmService();

  Stream<String?> askQuestion(String userQuery) async* {
    // 1. Retrieve data from your local SQLite DB
    final chunks = await FtsSearchService.searchContext(userQuery);

    // 2. Build the strict prompt
    final prompt = ContextBuilder.buildPrompt(userQuery, chunks);

    // 3. Yield the streaming response from Groq
    yield* _cloudLlmService.generateStream(prompt);
  }
}