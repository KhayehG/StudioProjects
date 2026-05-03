import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../utils/constants.dart';

class OpenAiService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> sendMessage(
    List<ChatMessage> history,
    String targetLanguage, {
    double averageQuizScore = 0.0,
    List<String> completedLessonTitles = const <String>[],
  }) async {
    try {
      final String lessonsSummary = completedLessonTitles.isEmpty
          ? 'none yet'
          : completedLessonTitles.join(', ');

      final String systemPrompt =
          'You are an expert and encouraging language tutor for '
          'LinguaFlow, a mobile language learning app. '
          'The user is currently practising $targetLanguage. '
          'Their current quiz average is ${averageQuizScore.toStringAsFixed(0)}%. '
          'They have completed the following lessons: '
          '$lessonsSummary. '
          'Based on their progress, personalise your responses: '
          'if their score is below 60%, use very simple vocabulary '
          'and lots of encouragement; '
          'if their score is 60–80%, introduce intermediate phrases '
          'and gently correct mistakes; '
          'if their score is above 80%, challenge them with more '
          'complex sentences and natural conversation. '
          'Always keep responses to 3 sentences maximum. '
          'Always respond in English but include words or phrases '
          'in $targetLanguage where helpful. '
          'Never break character as a language tutor.';

      final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'system',
          'content': systemPrompt,
        },
        ...history.map((ChatMessage m) => <String, dynamic>{
              'role': m.role == 'assistant' ? 'assistant' : 'user',
              'content': m.content,
            }),
      ];

      debugPrint('GROQ: Sending request...');

      final http.Response response = await http
          .post(
            Uri.parse(_endpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.groqApiKey}',
            },
            body: jsonEncode(<String, dynamic>{
              'model': 'llama-3.1-8b-instant',
              'messages': messages,
              'max_tokens': 300,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('GROQ: Status code: ${response.statusCode}');
      debugPrint('GROQ: Response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
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
