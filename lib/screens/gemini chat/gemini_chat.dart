// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'package:scheldule/utils/custom_text_form.dart';

class GeminiChat extends StatefulWidget {
  final VoidCallback onClose;
  final User user;

  GeminiChat({
    super.key,
    required this.onClose,
    required this.user,
  });

  @override
  State<GeminiChat> createState() => _GeminiChatState();
}

class _GeminiChatState extends State<GeminiChat> {
  final Gemini gemini = Gemini.instance;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    String userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "message": userMessage});
    });

    _textController.clear();
    _scrollToBottom();

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
          _scrollToBottom();
        }
      });
    } catch (e) {
      log("Error sending message to Gemini: $e");
    }
  }

  void _scrollToBottom() {
    Timer(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            child: SizedBox(
              width: double.infinity,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(
                    message: message["message"]!,
                    isUser: message["role"] == "user",
                    senderName: message["role"] == "user"
                        ? widget.user.displayName!
                        : "Gemini",
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextForm(
                    controller: _textController,
                    labelText: 'Type a message...',
                    hintText: '',
                    onSubmitted: (p0) => _sendMessage(),
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
  final String senderName;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: TextStyle(color: Colors.black87),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
