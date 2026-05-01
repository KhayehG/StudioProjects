import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../services/openai_service.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAiService _aiChatService = OpenAiService();
  String _selectedLanguage = 'English';
  int _dotPhase = 1;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() {
        _dotPhase = _dotPhase == 3 ? 1 : _dotPhase + 1;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _incrementChatCountAndAwardBadge() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final DocumentReference<Map<String, dynamic>> userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.set(
      <String, dynamic>{'chatMessageCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();
    final int count = (snapshot.data()?['chatMessageCount'] as num?)?.toInt() ?? 0;
    if (count >= 20) {
      await userRef.set(
        <String, dynamic>{
          'badgesEarned': FieldValue.arrayUnion(<String>['Chatbot Buddy']),
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    final ChatNotifier notifier = ref.read(chatProvider.notifier);
    _messageController.clear();
    notifier.addUserMessage(text);
    _scrollToBottom();

    final List<ChatMessage> history = ref.read(chatProvider).messages;
    final String reply = await _aiChatService.sendMessage(history, _selectedLanguage);
    notifier.addAssistantMessage(reply);
    _scrollToBottom();
    await _incrementChatCountAndAwardBadge();
  }

  String _formatTime(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildTypingIndicator() {
    final String dots = '.' * _dotPhase;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Typing$dots',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final bool isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2196F3) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatState state = ref.watch(chatProvider);
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Chat'),
        actions: <Widget>[
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: state.isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedLanguage = value;
                      });
                    },
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'isiZulu', child: Text('isiZulu')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(state.messages[index]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                      ),
                      enabled: !state.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: state.isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
