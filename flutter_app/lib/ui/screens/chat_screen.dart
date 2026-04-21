import 'package:flutter/material.dart';
import 'package:flutter_app/core/rag/rag_pipeline.dart';
import 'package:flutter_app/ui/widgets/chat_bubble.dart';

// Simple model
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RagPipeline _ragPipeline = RagPipeline();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isGenerating = false;

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isGenerating) return;

    final query = _textController.text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _messages.add(ChatMessage(text: "", isUser: false)); 
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      await for (final chunk in _ragPipeline.askQuestion(query)) {
        if (chunk != null) {
          setState(() {
            _messages.last = ChatMessage(
              text: _messages.last.text + chunk,
              isUser: false,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() {
        _messages.last = ChatMessage(text: "Error generating response.", isUser: false);
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline C# RAG Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(text: msg.text, isUser: msg.isUser);
              },
            ),
          ),
          if (_isGenerating) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Thinking...", 
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontStyle: FontStyle.italic)
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    // The styling for this is automatically pulled from theme.dart!
                    decoration: const InputDecoration(
                      hintText: "Ask a C# question...",
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}