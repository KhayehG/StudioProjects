import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final bool reminders = prefs.getBool('daily_reminders') ?? true;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
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
        .set({key: value}, SetOptions(merge: true));
    await _loadProfile();
  }

  Future<void> _editLanguage() async {
    String temp = (_userData?['selectedLanguage'] as String?) ?? 'English';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Learning Language'),
          content: DropdownButtonFormField<String>(
            initialValue: temp,
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'isiZulu', child: Text('isiZulu')),
              DropdownMenuItem(value: 'French', child: Text('French')),
              DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
            ],
            onChanged: (v) => temp = v ?? temp,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
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
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Daily Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [5, 10, 15]
                    .map(
                      (g) => RadioListTile<int>(
                        value: g,
                        groupValue: temp,
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => temp = v);
                          }
                        },
                        title: Text('$g minutes'),
                      ),
                    )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
    final prefs = await SharedPreferences.getInstance();
    setState(() => _dailyReminders = value);
    await prefs.setBool('daily_reminders', value);
    if (value) {
      await NotificationService().scheduleDailyReminder();
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> _signOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await AuthService().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _userData ?? {};
    final name = (data['name'] as String?) ?? 'Learner';
    final email = (data['email'] as String?) ?? '';
    final language = (data['selectedLanguage'] as String?) ?? 'English';
    final dailyGoal = (data['dailyGoal'] as num?)?.toInt() ?? 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2196F3),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Learning Language'),
                    subtitle: Text(language),
                    trailing: const Icon(Icons.edit),
                    onTap: _editLanguage,
                  ),
                  ListTile(
                    title: const Text('Daily Goal'),
                    subtitle: Text('$dailyGoal minutes'),
                    trailing: const Icon(Icons.edit),
                    onTap: _editDailyGoal,
                  ),
                  SwitchListTile(
                    value: _dailyReminders,
                    onChanged: _toggleReminders,
                    title: const Text('Daily Reminders'),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
