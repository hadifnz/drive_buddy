// lib/screens/chatbot_screen.dart

import 'package:flutter/material.dart';

// A simple data model for a chat message
class ChatMessage {
  final String text;
  final bool isUser; // True if the message is from the user

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add an initial greeting from the chatbot
    _messages.add(
      ChatMessage(
        text:
            "Hi! How can I help you today? You can ask me about warning lights or car symptoms.",
        isUser: false,
      ),
    );
  }

  void _sendMessage() {
    final text = _chatController.text;
    if (text.isEmpty) return;

    // Add the user's message to the list
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
    });

    _chatController.clear();

    // Get a response from the bot
    final botResponse = _getBotResponse(text);

    // Add the bot's response
    setState(() {
      _messages.insert(0, ChatMessage(text: botResponse, isUser: false));
    });
  }

  // This is your rule-based (offline) chatbot logic
  String _getBotResponse(String userInput) {
    String query = userInput.toLowerCase();

    // Example from your Figure 3.10
    if (query.contains("hrv") && query.contains("power steering")) {
      return "Your Honda HR-V (especially post-2016 models) doesn't have a traditional hydraulic power steering system—instead, it uses an electric power-steering (EPS) motor to assist steering.\n\nThat means there is no power steering fluid reservoir under the hood to locate or refill.";
    }

    // Add more rules based on your project scope
    if (query.contains("oil") && query.contains("light")) {
      return "An oil light usually means low oil pressure. Stop the car in a safe place, turn off the engine, and check the oil level. Do not drive with this light on.";
    }
    if (query.contains("engine") &&
        (query.contains("light") || query.contains("symbol"))) {
      return "The 'Check Engine' light can mean many things, from a loose gas cap to a serious engine issue. I recommend getting a diagnostic check (OBD-II scan) as soon as possible.";
    }
    if (query.contains("battery")) {
      return "A battery light indicates a problem with the charging system, likely the alternator or the battery itself. Get it checked soon, as your car may stall.";
    }

    // Default response
    return "Sorry, I'm not sure how to help with that. Please try rephrasing your question.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Drive Chat',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              reverse: true, // Makes the list start from the bottom
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          // Text input field
          _buildTextInput(),
        ],
      ),
    );
  }

  // Helper for the text input bar at the bottom
  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade900,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Helper for building a single chat bubble
  Widget _buildChatBubble(ChatMessage message) {
    // Align user messages to the right, bot messages to the left
    bool isUser = message.isUser;
    CrossAxisAlignment alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    Color bubbleColor = isUser ? Colors.grey.shade800 : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // This is the little chatbot icon, only shown for bot messages
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.android, color: Colors.white, size: 20),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // This is the 'D' user icon, only shown for user messages
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Text('D', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
