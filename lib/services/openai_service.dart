import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../utils/constants.dart';

class OpenAiService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> sendMessage(
      List<ChatMessage> history, String targetLanguage) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content':
              'You are a friendly and encouraging language tutor '
              'for the LinguaFlow app. The user is practicing '
              '$targetLanguage. Keep responses to 2-3 sentences. '
              'Gently correct grammar mistakes by showing the '
              'correct version. Always encourage the user.',
        },
        ...history.map((m) => {
          'role': m.role == 'assistant' ? 'assistant' : 'user',
          'content': m.content,
        }),
      ];

      debugPrint('GROQ: Sending request...');

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('GROQ: Status code: ${response.statusCode}');
      debugPrint('GROQ: Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']
            .toString()
            .trim();
      } else {
        debugPrint('GROQ ERROR: ${response.statusCode} ${response.body}');
        return 'Sorry, something went wrong. Please try again.';
      }
    } catch (e, stack) {
      debugPrint('GROQ EXCEPTION: $e');
      debugPrint('GROQ STACK: $stack');
      return 'Connection error. Check your internet and try again.';
    }
  }
}
