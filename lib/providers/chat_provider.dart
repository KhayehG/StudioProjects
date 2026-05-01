import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  ChatState({required this.messages, required this.isLoading});
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: [], isLoading: false));

  void addUserMessage(String text) {
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      ],
      isLoading: true,
    );
  }

  void addAssistantMessage(String text) {
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          role: 'assistant',
          content: text,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }

  void setLoading(bool loading) {
    state = ChatState(messages: state.messages, isLoading: loading);
  }

  void clearChat() {
    state = ChatState(messages: [], isLoading: false);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
