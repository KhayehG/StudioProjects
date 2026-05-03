import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/certificate_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  bool _loading = true;
  List<String> _certificates = <String>[];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final List<String> list = List<String>.from(
        doc.data()?['certificates'] as List<dynamic>? ?? <dynamic>[],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _certificates = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load certificates: $e')),
      );
    }
  }

  String _languageFromCert(String cert) {
    return cert
        .replaceAll('advanced_', '')
        .split('_')
        .where((String w) => w.isNotEmpty)
        .map(
          (String w) =>
              '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}',
        )
        .join(' ');
  }

  Future<void> _downloadCertificate(String language) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating certificate...')),
    );
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final String? rawName = doc.data()?['name'] as String?;
      final String userName =
          (rawName != null && rawName.trim().isNotEmpty) ? rawName.trim() : 'Learner';
      await CertificateService().generateAndShareCertificate(
        userName: userName,
        language: language,
        score: 100,
        dateEarned: DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate ready!')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate certificate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: const Color(0xFFF0F2F8),
        foregroundColor: const Color(0xFF1a1d2e),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? _EmptyCertificates(onGoToLessons: () => context.push('/lessons'))
              : RefreshIndicator(
                  onRefresh: _loadCertificates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _certificates.length,
                    itemBuilder: (BuildContext context, int i) {
                      final String cert = _certificates[i];
                      final String lang = _languageFromCert(cert);
                      return NeuCard(
                        small: true,
                        margin: const EdgeInsets.only(bottom: 12),
                        onTap: () => _downloadCertificate(lang),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.workspace_premium,
                                color: Color(0xFFe67e22),
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      lang,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1a1d2e),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Advanced Level',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF7c82a0),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to download',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6C5CE7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.download,
                                color: Color(0xFF6C5CE7),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyCertificates extends StatelessWidget {
  const _EmptyCertificates({required this.onGoToLessons});

  final VoidCallback onGoToLessons;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.workspace_premium,
              size: 64,
              color: Color(0xFF7c82a0),
            ),
            const SizedBox(height: 16),
            const Text(
              'No certificates yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a1d2e),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete Advanced level quizzes with 80%+ to earn certificates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7c82a0),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Go to Lessons',
              onPressed: onGoToLessons,
            ),
          ],
        ),
      ),
    );
  }
}
