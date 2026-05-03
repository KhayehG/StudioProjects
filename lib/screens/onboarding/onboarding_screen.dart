import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

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
          'currentLanguage': _selectedLanguage,
          'dailyGoal': _selectedGoal,
        },
        SetOptions(merge: true),
      );

      await NotificationService().scheduleDailyReminder(hour: 8, minute: 0);
      await NotificationService().getFCMToken();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
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
      children: List<Widget>.generate(3, (int index) {
        final bool isActive = index == _currentPage;
        if (isActive) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: NeuCard(
              small: true,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B6BE8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFD1D3D8),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Onboarding'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
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
                  onPageChanged: (int index) => setState(() => _currentPage = index),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const NeuCard(
                              borderRadius: 50,
                              width: 100,
                              height: 100,
                              padding: EdgeInsets.zero,
                              child: Icon(Icons.language, size: 50, color: Color(0xFF5B6BE8)),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Welcome to LinguaFlow',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Learn Languages Smarter with AI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            GradientButton(label: 'Next →', onPressed: _nextPage),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              'What would you like to learn?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const SizedBox(height: 20),
                            NeuCard(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedLanguage,
                                decoration: const InputDecoration(labelText: 'Language'),
                                hint: const Text('Select language'),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(value: 'English', child: Text('English')),
                                  DropdownMenuItem<String>(value: 'isiZulu', child: Text('isiZulu')),
                                  DropdownMenuItem<String>(value: 'French', child: Text('French')),
                                  DropdownMenuItem<String>(value: 'Spanish', child: Text('Spanish')),
                                ],
                                onChanged: (String? value) => setState(() => _selectedLanguage = value),
                              ),
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              label: 'Next →',
                              onPressed: _selectedLanguage == null ? null : _nextPage,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              'Set your daily goal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...<int>[5, 10, 15].map((int goal) {
                              final bool selected = _selectedGoal == goal;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedGoal = goal),
                                  child: NeuCard(
                                    small: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: selected
                                            ? const Border(
                                                left: BorderSide(
                                                  color: Color(0xFF5B6BE8),
                                                  width: 3,
                                                ),
                                              )
                                            : null,
                                      ),
                                      width: double.infinity,
                                      child: Text(
                                        '⏱ $goal minutes',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              selected ? FontWeight.bold : FontWeight.w500,
                                          color: const Color(0xFF2D2F45),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            GradientButton(
                              label: 'Get Started 🚀',
                              isLoading: _isSubmitting,
                              onPressed: (_selectedGoal == null || _isSubmitting)
                                  ? null
                                  : _finishOnboarding,
                            ),
                          ],
                        ),
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
