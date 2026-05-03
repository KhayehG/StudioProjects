import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _dailyReminders = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool reminders = prefs.getBool('daily_reminders') ?? true;
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _dailyReminders = reminders;
        _userData = doc.data();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $error')),
      );
    }
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _updateField(String key, dynamic value) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(<String, dynamic>{key: value}, SetOptions(merge: true));
    await _loadProfile();
  }

  Future<void> _editLanguage() async {
    String temp = (_userData?['selectedLanguage'] as String?) ?? 'English';
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Learning Language'),
          content: DropdownButtonFormField<String>(
            initialValue: temp,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'English', child: Text('English')),
              DropdownMenuItem<String>(value: 'isiZulu', child: Text('isiZulu')),
              DropdownMenuItem<String>(value: 'French', child: Text('French')),
              DropdownMenuItem<String>(value: 'Spanish', child: Text('Spanish')),
            ],
            onChanged: (String? v) => temp = v ?? temp,
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, temp),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _updateField('selectedLanguage', result);
    }
  }

  Future<void> _editDailyGoal() async {
    int temp = (_userData?['dailyGoal'] as num?)?.toInt() ?? 10;
    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            return AlertDialog(
              title: const Text('Change Daily Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <int>[5, 10, 15].map((int g) {
                  final bool sel = temp == g;
                  return ListTile(
                    title: Text('$g minutes'),
                    leading: Icon(
                      sel ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: sel ? const Color(0xFF5B6BE8) : const Color(0xFF9A9EB5),
                    ),
                    onTap: () => setDialogState(() => temp = g),
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await _updateField('dailyGoal', result);
    }
  }

  Future<void> _toggleReminders(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _dailyReminders = value);
    await prefs.setBool('daily_reminders', value);
    if (value) {
      await NotificationService().scheduleDailyReminder(hour: 8, minute: 0);
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> _signOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await AuthService().signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEF0F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Map<String, dynamic> data = _userData ?? <String, dynamic>{};
    final String name = (data['name'] as String?) ?? 'Learner';
    final String email = (data['email'] as String?) ?? '';
    final String language = (data['selectedLanguage'] as String?) ?? 'English';
    final int dailyGoal = (data['dailyGoal'] as num?)?.toInt() ?? 10;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            NeuCard(
              borderRadius: 50,
              width: 80,
              height: 80,
              padding: EdgeInsets.zero,
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Color(0xFF5B6BE8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            NeuCard(
              child: ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2F45),
                  ),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(color: Color(0xFF9A9EB5)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            NeuCard(
              small: true,
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text(
                      'Learning Language',
                      style: TextStyle(color: Color(0xFF2D2F45)),
                    ),
                    subtitle: Text(
                      language,
                      style: const TextStyle(color: Color(0xFF9A9EB5)),
                    ),
                    trailing: const Icon(Icons.edit, color: Color(0xFF5B6BE8)),
                    onTap: _editLanguage,
                  ),
                  ListTile(
                    title: const Text(
                      'Daily Goal',
                      style: TextStyle(color: Color(0xFF2D2F45)),
                    ),
                    subtitle: Text(
                      '$dailyGoal minutes',
                      style: const TextStyle(color: Color(0xFF9A9EB5)),
                    ),
                    trailing: const Icon(Icons.edit, color: Color(0xFF5B6BE8)),
                    onTap: _editDailyGoal,
                  ),
                  SwitchListTile(
                    value: _dailyReminders,
                    onChanged: _toggleReminders,
                    activeTrackColor: const Color(0xFF5B6BE8),
                    title: const Text(
                      'Daily Reminders',
                      style: TextStyle(color: Color(0xFF2D2F45)),
                    ),
                  ),
                  NeuCard(
                    small: true,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFe67e22),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'My Certificates',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1d2e),
                        ),
                      ),
                      subtitle: const Text(
                        'View and download',
                        style: TextStyle(
                          color: Color(0xFF7c82a0),
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF7c82a0),
                      ),
                      onTap: () => context.push('/certificates'),
                    ),
                  ),
                  NeuCard(
                    small: true,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Color(0xFF3498db),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Test Notification',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1d2e),
                        ),
                      ),
                      subtitle: const Text(
                        'Send a test notification now',
                        style: TextStyle(
                          color: Color(0xFF7c82a0),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        await NotificationService().showTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Sign Out',
              color: const Color(0xFFE05A5A),
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
