import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, required this.isLoading});
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: <ChatMessage>[], isLoading: false));

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Loads the last 50 messages, oldest first.
  Future<void> loadChatHistory(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection('users')
          .doc(userId)
          .collection('chatHistory')
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get();

      final List<ChatMessage> loaded = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                ChatMessage.fromMap(d.data()),
          )
          .toList();

      state = ChatState(messages: loaded, isLoading: false);
    } catch (e, st) {
      debugPrint('loadChatHistory error: $e');
      debugPrint('$st');
    }
  }

  Future<void> saveChatMessage(String userId, ChatMessage message) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('chatHistory')
          .add(message.toMap());
    } catch (e, st) {
      debugPrint('saveChatMessage error: $e');
      debugPrint('$st');
    }
  }

  void addUserMessage(String text, {required String userId}) {
    final ChatMessage message = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    state = ChatState(
      messages: <ChatMessage>[...state.messages, message],
      isLoading: true,
    );
    unawaited(saveChatMessage(userId, message));
  }

  void addAssistantMessage(String text, {required String userId}) {
    final ChatMessage message = ChatMessage(
      role: 'assistant',
      content: text,
      timestamp: DateTime.now(),
    );
    state = ChatState(
      messages: <ChatMessage>[...state.messages, message],
      isLoading: false,
    );
    unawaited(saveChatMessage(userId, message));
  }

  void setLoading(bool loading) {
    state = ChatState(messages: state.messages, isLoading: loading);
  }

  Future<void> clearChat(String? userId) async {
    if (userId != null) {
      try {
        const int page = 500;
        while (true) {
          final QuerySnapshot<Map<String, dynamic>> snap = await _db
              .collection('users')
              .doc(userId)
              .collection('chatHistory')
              .limit(page)
              .get();
          if (snap.docs.isEmpty) {
            break;
          }
          final WriteBatch batch = _db.batch();
          for (final QueryDocumentSnapshot<Map<String, dynamic>> d
              in snap.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
      } catch (e, st) {
        debugPrint('clearChat error: $e');
        debugPrint('$st');
      }
    }
    state = ChatState(messages: <ChatMessage>[], isLoading: false);
  }
}

final StateNotifierProvider<ChatNotifier, ChatState> chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>(
  (Ref ref) => ChatNotifier(),
);
