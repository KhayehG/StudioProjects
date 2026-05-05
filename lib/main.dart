import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/notification_service.dart';
import 'utils/router.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const ProviderScope(child: LinguaFlowApp()));
}

class LinguaFlowApp extends StatelessWidget {
  const LinguaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LinguaFlow',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: appTheme,
    );
  }
}
