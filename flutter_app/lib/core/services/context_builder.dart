class ContextBuilder {
  static String buildPrompt(String userQuery, List<String> contextChunks) {
    if (contextChunks.isEmpty) {
      return "Based on the local C# database, I could not find an answer to: $userQuery. Please answer based on your general knowledge but mention that it wasn't in the local database.";
    }

    String combinedContext = contextChunks.join("\n\n---\n\n");

    return '''You are an expert C# offline coding assistant. 
You MUST answer the user's question using ONLY the provided StackOverflow Context. 
If the Context does not contain the answer, reply exactly with: "I don't know based on the local database."
Do not write code that is not supported by the Context.

CONTEXT:
$combinedContext

QUESTION:
$userQuery''';
  }
}
