import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/sign_lesson.dart';
import '../../services/sign_lesson_service.dart';
import '../../widgets/glass_card.dart';

class SignLanguageScreen extends StatefulWidget {
  const SignLanguageScreen({super.key});

  @override
  State<SignLanguageScreen> createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  final SignLessonService _signLessonService = SignLessonService();
  List<SignLesson> _lessons = <SignLesson>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _loading = true);
    final List<SignLesson> list = await _signLessonService.fetchAllSignLessons();
    if (!mounted) return;
    setState(() {
      _lessons = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Sign Language — A to Z'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.sign_language,
                          size: 56,
                          color: const Color(0xFF9A9EB5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No sign lessons found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull to refresh after seeding sign_lessons in Firestore.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loadLessons,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5B6BE8),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: NeuCard(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'American Sign Language (ASL)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D2F45),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_lessons.length} letters',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9A9EB5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _lessons.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SignLesson lesson = _lessons[index];
                          return NeuCard(
                            small: true,
                            onTap: () {
                              context.push('/sign-detail', extra: lesson);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  lesson.letter,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B6BE8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Center(
                                    child: Image.network(
                                      lesson.imageUrl,
                                      height: 90,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (
                                        BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const SizedBox(
                                          height: 90,
                                          child: Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.sign_language,
                                          size: 40,
                                          color: Color(0xFF9A9EB5),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lesson.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9A9EB5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
