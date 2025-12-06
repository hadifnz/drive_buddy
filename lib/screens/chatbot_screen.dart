// lib/screens/chatbot_screen.dart

import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/models/trip_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  final Car car;
  const ChatbotScreen({super.key, required this.car});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isModelInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGeminiWithContext();
  }

  void _initializeGeminiWithContext() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      _addSystemMessage("Error: No GEMINI_API_KEY found.");
      return;
    }

    try {
      // 1. SAFELY FETCH HISTORY
      // Check if box is open first to prevent crashes
      if (!Hive.isBoxOpen('trip_sessions')) {
        await Hive.openBox<TripSession>('trip_sessions');
      }

      final tripBox = Hive.box<TripSession>('trip_sessions');
      final carTrips = tripBox.values
          .where((t) => t.carKey == widget.car.key)
          .toList();

      int totalHarshBrakes = 0;
      int totalSharpTurns = 0;
      for (var t in carTrips) {
        totalHarshBrakes += t.harshBrakingCount;
        totalSharpTurns += t.sharpTurnCount;
      }

      // 2. BUILD CONTEXT
      // Using ?? 'N/A' prevents crashes on old car data
      final String carContext =
          """
      VEHICLE CONTEXT:
      - Car: ${widget.car.brand} ${widget.car.model}
      - Plate: ${widget.car.plateNumber}
      - Engine: ${widget.car.engineCapacity ?? 'N/A'} ${widget.car.engine ?? ''}
      - Transmission: ${widget.car.transmissionType ?? 'N/A'}
      - Mileage: ${widget.car.currentMileage.toStringAsFixed(1)} km
      - Oil Type: ${widget.car.oilType ?? 'N/A'}
      
      DRIVING HISTORY (Last ${carTrips.length} trips):
      - Total Harsh Braking Events: $totalHarshBrakes
      - Total Sharp Turns: $totalSharpTurns
      
      INSTRUCTIONS:
      You are Drive Buddy. Use the vehicle context above.
      If the transmission is CVT, DO NOT suggest checking 'ATF', suggest 'CVT Fluid'.
      Only answer automotive questions.
      """;

      // 3. INITIALIZE GEMINI (USING THE MODEL FROM YOUR LOGS)
      _model = GenerativeModel(
        // --- CHANGED MODEL HERE ---
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      _chatSession = _model.startChat(
        history: [
          Content.text(carContext),
          Content.model([TextPart('Understood. I have the vehicle context.')]),
        ],
      );

      if (mounted) {
        setState(() {
          _isModelInitialized = true;
          // Insert at index 0 so it appears at the bottom (because of reverse: true)
          _messages.insert(
            0,
            ChatMessage(
              text:
                  "Hi! I'm ready to help with your ${widget.car.brand} ${widget.car.model}.",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      print("Gemini Init Error: $e");
      _addSystemMessage("Connection failed: $e");
    }
  }

  void _addSystemMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: false));
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (!_isModelInitialized) {
      _addSystemMessage("Chatbot not ready. Check internet or restart.");
      return;
    }

    final text = _chatController.text;
    if (text.isEmpty) return;

    // 1. Add User Message
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isBotTyping = true;
    });

    _chatController.clear();

    try {
      // 2. Send to API
      final response = await _chatSession.sendMessage(Content.text(text));
      final botText = response.text;

      if (botText != null) {
        setState(() {
          _messages.insert(0, ChatMessage(text: botText.trim(), isUser: false));
        });
      }
    } catch (e) {
      print("Send Error: $e");
      _addSystemMessage("Error sending message. Try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isBotTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${widget.car.plateNumber} Chat',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Fills from bottom up
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          if (_isBotTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Analyzing...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          _buildTextInput(),
        ],
      ),
    );
  }

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
                hintText: 'Ask about a problem...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
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

  Widget _buildChatBubble(ChatMessage message) {
    bool isUser = message.isUser;
    Color bubbleColor = isUser ? Colors.grey.shade800 : Colors.grey.shade700;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.android, color: Colors.white),
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
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
