import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../services/openai_service.dart';
import '../../services/xp_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';

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
  double _userAverageScore = 0.0;
  List<String> _completedLessonTitles = <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
    _typingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dotPhase = _dotPhase == 3 ? 1 : _dotPhase + 1;
      });
    });
  }

  Future<void> _bootstrap() async {
    await _loadUserContext();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && mounted) {
      await ref.read(chatProvider.notifier).loadChatHistory(uid);
    }
  }

  Future<void> _loadUserContext() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return;
      }

      final FirebaseFirestore db = FirebaseFirestore.instance;

      final QuerySnapshot<Map<String, dynamic>> quizSnap = await db
          .collection('users')
          .doc(uid)
          .collection('quizResults')
          .get();

      final List<int> pcts = <int>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in quizSnap.docs) {
        final int p = (doc.data()['percentage'] as num?)?.round() ?? 0;
        pcts.add(p);
      }
      final double avg = pcts.isEmpty
          ? 0.0
          : pcts.reduce((int a, int b) => a + b) / pcts.length;

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('users').doc(uid).get();
      final List<dynamic> completedRaw =
          userDoc.data()?['completedLessons'] as List<dynamic>? ?? <dynamic>[];
      final List<String> completedIds = completedRaw
          .map((dynamic e) => e.toString())
          .where((String id) => id.isNotEmpty)
          .toList();

      final List<String> titles = <String>[];
      const int chunk = 10;
      for (int i = 0; i < completedIds.length; i += chunk) {
        final List<String> slice = completedIds.sublist(
          i,
          i + chunk > completedIds.length ? completedIds.length : i + chunk,
        );
        if (slice.isEmpty) {
          continue;
        }
        final QuerySnapshot<Map<String, dynamic>> lessonsSnap = await db
            .collection('lessons')
            .where(FieldPath.documentId, whereIn: slice)
            .get();

        final Map<String, String> idToTitle = <String, String>{};
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d
            in lessonsSnap.docs) {
          idToTitle[d.id] = (d.data()['title'] as String?)?.trim() ?? '';
        }
        for (final String lessonId in slice) {
          final String t = idToTitle[lessonId] ?? '';
          if (t.isNotEmpty) {
            titles.add(t);
          }
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _userAverageScore = avg;
        _completedLessonTitles = titles;
      });
    } catch (_) {
      return;
    }
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
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _incrementChatCountAndAwardBadge() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);

    final DocumentSnapshot<Map<String, dynamic>> beforeSnap = await userRef.get();
    final int beforeCount =
        (beforeSnap.data()?['chatMessageCount'] as num?)?.toInt() ?? 0;

    await userRef.set(
      <String, dynamic>{'chatMessageCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    final DocumentSnapshot<Map<String, dynamic>> afterSnap = await userRef.get();
    final int count = (afterSnap.data()?['chatMessageCount'] as num?)?.toInt() ?? 0;

    if (count > 0 && count ~/ 10 > beforeCount ~/ 10) {
      await XpService().awardXp(uid, AppConstants.xpChatbot10);
      debugPrint('XP: +5 XP for 10 chatbot messages');
    }

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
    if (text.isEmpty) {
      return;
    }

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final ChatNotifier notifier = ref.read(chatProvider.notifier);
    _messageController.clear();
    notifier.addUserMessage(text, userId: uid);
    _scrollToBottom();

    final List<ChatMessage> history = ref.read(chatProvider).messages;
    final String reply = await _aiChatService.sendMessage(
      history,
      _selectedLanguage,
      averageQuizScore: _userAverageScore,
      completedLessonTitles: _completedLessonTitles,
    );
    notifier.addAssistantMessage(reply, userId: uid);
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
      child: NeuCard(
        small: true,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'Typing$dots',
          style: const TextStyle(color: Color(0xFF2D2F45)),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final bool isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          if (isUser)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: const Color(0xFF5B6BE8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF4A58C8).withValues(alpha: 0.3),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: const TextStyle(color: Colors.white),
              ),
            )
          else
            NeuCard(
              small: true,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  message.content,
                  style: const TextStyle(color: Color(0xFF2D2F45)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Color(0xFF9A9EB5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neuInputShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0xFFD1D3D8),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatState state = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Practice Chat'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: NeuCard(
              small: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: state.isLoading
                      ? null
                      : (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedLanguage = value;
                          });
                        },
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'English',
                      child: Text('English'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'isiZulu',
                      child: Text('isiZulu'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'French',
                      child: Text('French'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Spanish',
                      child: Text('Spanish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF2D2F45)),
            onPressed: () {
              final String? uid = FirebaseAuth.instance.currentUser?.uid;
              unawaited(ref.read(chatProvider.notifier).clearChat(uid));
            },
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
              itemBuilder: (BuildContext context, int index) {
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
                    child: _neuInputShell(
                      child: TextFormField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        enabled: !state.isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: state.isLoading ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5B6BE8),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
