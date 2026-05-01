import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'linguaflow_reminders',
      'Daily Reminders',
      description: 'Daily practice reminders for LinguaFlow',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'linguaflow_reminders',
      'Daily Reminders',
      channelDescription: 'Daily practice reminders for LinguaFlow',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.periodicallyShow(
      1001,
      'Time to practice! 🔥',
      'Keep your LinguaFlow streak going!',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
