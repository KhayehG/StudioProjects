import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/sign_lesson.dart';
import '../../widgets/glass_card.dart';

class SignDetailScreen extends StatelessWidget {
  const SignDetailScreen({required this.lesson, super.key});

  final SignLesson lesson;

  static const Color _accent = Color(0xFF5B6BE8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: Text('Letter ${lesson.letter}'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NeuCard(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  lesson.letter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B6BE8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            NeuCard(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Image.network(
                  lesson.imageUrl,
                  height: 200,
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
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.sign_language,
                          size: 80,
                          color: Color(0xFF9A9EB5),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Color(0xFF9A9EB5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            NeuCard(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'HOW TO SIGN IT',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A9EB5),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D2F45),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            NeuCard(
              small: true,
              padding: EdgeInsets.zero,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _accent,
                      width: 3,
                    ),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PRACTICE TIP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A9EB5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hold the sign for 2-3 seconds and compare it with the image above. '
                      'Practice in front of a mirror for best results.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D2F45),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                if (lesson.order > 1)
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: NeuCard(
                      small: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.arrow_back, color: Color(0xFF2D2F45)),
                          SizedBox(width: 6),
                          Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2F45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    context.push('/sign-camera', extra: lesson.letter);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35),
                          offset: const Offset(3, 3),
                          blurRadius: 8,
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Test Sign',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
