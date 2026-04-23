class ContextBuilder {
  /// After scope check passed as C# but FTS returned nothing: answer from model knowledge, C#/.NET only.
  static String buildUngroundedCSharpPrompt(String userQuery) {
    return '''You are a C# and .NET programming assistant.

Nothing in the user's local knowledge base matched their question, but their question was already confirmed to be about C# or .NET development.

Answer using your general knowledge of C# and .NET only (language, BCL, runtime, common libraries, idioms). Do not pivot to unrelated topics or other ecosystems unless the question explicitly asks for a brief comparison.

The user interface already stated that this answer is not from the local database; do not repeat that disclaimer—go straight into the technical answer.

If you still cannot answer as a C#/.NET developer question, say so briefly.

QUESTION:
$userQuery''';
  }

  /// Builds a prompt for the LLM. [contextChunks] must be non-empty (caller gates retrieval).
  static String buildPrompt(String userQuery, List<String> contextChunks) {
    assert(contextChunks.isNotEmpty);

    final combinedContext = contextChunks.join("\n\n---\n\n");

    return '''You are a C# / .NET assistant that may ONLY use the CONTEXT below (local Stack Overflow–style snippets). You must NOT use outside knowledge.

Rules:
1. If the user's question is not about C#, .NET, or programming topics that the CONTEXT could reasonably support, reply with exactly this single line and nothing else:
I only answer C# questions supported by the local knowledge base.
2. If the question is on-topic but the CONTEXT does not contain enough information to answer safely, reply with exactly:
I don't know based on the local database.
3. Otherwise answer using ONLY what is stated or clearly implied in the CONTEXT. Do not invent APIs, syntax, or behavior.

CONTEXT:
$combinedContext

QUESTION:
$userQuery''';
  }
}
