import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/lessons/lesson_detail_screen.dart';
import '../screens/lessons/lessons_screen.dart';
import '../screens/lessons/speech_practice_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/certificates_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../models/sign_lesson.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/sign_language/sign_camera_screen.dart';
import '../screens/sign_language/sign_detail_screen.dart';
import '../screens/sign_language/sign_language_screen.dart';
import '../screens/vocabulary/flashcard_screen.dart';
import '../screens/vocabulary/vocabulary_screen.dart';
import '../widgets/main_shell.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    final bool loggedIn = user != null;
    final bool onLoginPage = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password';

    if (!loggedIn) {
      return onLoginPage ? null : '/login';
    }

    if (!onboardingDone && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    if (onboardingDone && state.matchedLocation == '/onboarding') {
      return '/home';
    }

    if (onLoginPage) {
      return '/home';
    }

    if (state.matchedLocation == '/') {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (c, s) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', redirect: (c, s) => '/home'),
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/lessons', builder: (c, s) => const LessonsScreen()),
        GoRoute(
          path: '/lesson-detail/:id',
          builder: (c, s) => LessonDetailScreen(lessonId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/vocabulary', builder: (c, s) => const VocabularyScreen()),
        GoRoute(path: '/flashcards', builder: (c, s) => const FlashcardScreen()),
        GoRoute(
          path: '/quiz/:id',
          builder: (c, s) => QuizScreen(lessonId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/speech-practice',
          builder: (c, s) => const SpeechPracticeScreen(),
        ),
        GoRoute(
          path: '/sign-language',
          builder: (c, s) => const SignLanguageScreen(),
        ),
        GoRoute(
          path: '/sign-detail',
          builder: (c, s) {
            final SignLesson lesson = s.extra as SignLesson;
            return SignDetailScreen(lesson: lesson);
          },
        ),
        GoRoute(
          path: '/sign-camera',
          builder: (c, s) {
            final String? letter = s.extra as String?;
            return SignCameraScreen(targetLetter: letter);
          },
        ),
        GoRoute(path: '/chatbot', builder: (c, s) => const ChatbotScreen()),
        GoRoute(path: '/progress', builder: (c, s) => const ProgressScreen()),
        GoRoute(
          path: '/certificates',
          builder: (BuildContext c, GoRouterState s) =>
              const CertificatesScreen(),
        ),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
    ),
  ],
);
