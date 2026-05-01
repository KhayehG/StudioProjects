import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedLanguage;
  int? _selectedGoal;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedLanguage == null || _selectedGoal == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.set(
        <String, dynamic>{
          'selectedLanguage': _selectedLanguage,
          'dailyGoal': _selectedGoal,
        },
        SetOptions(merge: true),
      );

      final NotificationService notificationService = NotificationService();
      await notificationService.scheduleDailyReminder();
      final String? token = await notificationService.getFCMToken();
      if (token != null) {
        await userRef.set(<String, dynamic>{'fcmToken': token}, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete onboarding: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (index) {
        final bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2196F3) : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.language, size: 80, color: Color(0xFF2196F3)),
                        const SizedBox(height: 18),
                        const Text(
                          'Welcome to LinguaFlow',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Learn Languages Smarter with AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _nextPage,
                          child: const Text('Next →'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'What would you like to learn?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          decoration: const InputDecoration(labelText: 'Language'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'isiZulu', child: Text('isiZulu')),
                            DropdownMenuItem(value: 'French', child: Text('French')),
                            DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                          ],
                          onChanged: (value) => setState(() => _selectedLanguage = value),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _selectedLanguage == null ? null : _nextPage,
                          child: const Text('Next →'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Set your daily goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ...<int>[5, 10, 15].map((goal) {
                          final bool selected = _selectedGoal == goal;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGoal = goal),
                            child: Card(
                              color: selected ? const Color(0xFFBBDEFB) : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      '⏱ $goal minutes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            selected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (_selectedGoal == null || _isSubmitting)
                              ? null
                              : _finishOnboarding,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Get Started 🚀'),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(height: 8),
              _buildPageIndicator(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
