import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      final tz.Location location = tz.getLocation('Africa/Johannesburg');
      tz.setLocalLocation(location);
      debugPrint('NOTIFICATION: Timezone set to Africa/Johannesburg');

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: DarwinInitializationSettings(),
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('NOTIFICATION tapped: ${details.payload}');
        },
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'linguaflow_reminders',
          'Daily Reminders',
          description: 'Daily study reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'linguaflow_certificates',
          'Certificates',
          description: 'Certificate achievements',
          importance: Importance.high,
        ),
      );

      final bool? granted =
          await androidPlugin?.requestNotificationsPermission();
      debugPrint('NOTIFICATION: Permission=$granted');

      _initialized = true;
      debugPrint('NOTIFICATION: Initialized.');
    } catch (e) {
      debugPrint('NOTIFICATION init error: $e');
    }
  }

  Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.cancelAll();
      debugPrint('NOTIFICATION: Scheduling daily reminder at $hour:$minute');

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      debugPrint('NOTIFICATION: Current local time: $now');

      tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      debugPrint('NOTIFICATION: Will fire at: $scheduled');

      await _plugin.zonedSchedule(
        1,
        'Time to practise! 🔥',
        'Keep your LinguaFlow streak going!',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'linguaflow_reminders',
            'Daily Reminders',
            channelDescription: 'Daily study reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'NOTIFICATION: Daily reminder scheduled successfully for '
        '$hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e, stack) {
      debugPrint('NOTIFICATION schedule error: $e');
      debugPrint('NOTIFICATION stack: $stack');
    }
  }

  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        999,
        'LinguaFlow 👋',
        'Notifications are working correctly!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'linguaflow_reminders',
            'Daily Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      debugPrint('NOTIFICATION: Test notification sent');
    } catch (e) {
      debugPrint('NOTIFICATION test error: $e');
    }
  }

  Future<void> showCertificateNotification({
    required String userName,
    required String language,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '🏆 Certificate Earned!',
        '$userName completed $language Advanced!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'linguaflow_certificates',
            'Certificates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      debugPrint('NOTIFICATION: Certificate shown');
    } catch (e) {
      debugPrint('NOTIFICATION cert error: $e');
    }
  }

  Future<void> showCertificatePdfSavedNotification({
    required String fileName,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000) + 7,
        '📥 Certificate saved',
        '$fileName is on your device.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'linguaflow_certificates',
            'Certificates',
            channelDescription: 'Certificate achievements',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      debugPrint('NOTIFICATION: Certificate PDF saved ($fileName)');
    } catch (e) {
      debugPrint('NOTIFICATION ERROR: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('NOTIFICATION: All cancelled');
  }

  Future<String?> getFCMToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(<String, dynamic>{'fcmToken': token}, SetOptions(merge: true));
        }
      }
      return token;
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }
}
