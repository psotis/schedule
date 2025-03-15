import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:scheldule/utils/custom_text_form.dart';

class GeminiChat extends StatefulWidget {
  final VoidCallback onClose;

  GeminiChat({required this.onClose});

  @override
  State<GeminiChat> createState() => _GeminiChatState();
}

class _GeminiChatState extends State<GeminiChat> {
  final Gemini gemini = Gemini.instance;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Stores chat messages

  void _sendMessage() async {
    String userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "message": userMessage});
    });

    _textController.clear();

    try {
      gemini.promptStream(safetySettings: [
        SafetySetting(
          category: SafetyCategory.harassment,
          threshold: SafetyThreshold.blockLowAndAbove,
        ),
        SafetySetting(
          category: SafetyCategory.hateSpeech,
          threshold: SafetyThreshold.blockOnlyHigh,
        )
      ], parts: [
        Part.text(userMessage)
      ]).listen((response) {
        if (response?.output != null) {
          setState(() {
            _messages.add({"role": "gemini", "message": response!.output!});
          });
        }
      });
    } catch (e) {
      log("Error sending message to Gemini: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF00c9b7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message["message"]!,
                  isUser: message["role"] == "user",
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextForm(
                    controller: _textController,
                    labelText: '',
                    hintText: 'Type a message...',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Color(0xFF00c9b7),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
