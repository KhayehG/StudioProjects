import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toApiMap() => <String, dynamic>{
        'role': role,
        'content': content,
      };

  /// Firestore document fields: [role], [content], [timestamp].
  Map<String, dynamic> toMap() => <String, dynamic>{
        'role': role,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  static ChatMessage fromMap(Map<String, dynamic> map) {
    final dynamic rawTs = map['timestamp'];
    DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      ts = DateTime.now();
    }
    return ChatMessage(
      role: map['role'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      timestamp: ts,
    );
  }
}
