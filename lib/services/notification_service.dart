import 'package:dayplanner/services/task_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {},
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId',
          'channelName',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showScheduledNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required List<AndroidNotificationAction> actions,
    required String payload,
  }) async {
    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId',
          'channelName',
          importance: Importance.max,
          priority: Priority.high,
          actions: actions,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse notificationResponse) async {
  await Firebase.initializeApp();
  String? payload = notificationResponse.payload;
  if (payload != null) {
    List<String> payloadParts = payload.split('|');
    if (notificationResponse.actionId == 'yes_action') {
      String userID = payloadParts[0];
      String taskID = payloadParts[1];
      String formattedDate = payloadParts[2];
      await updateStatus(userID, taskID, formattedDate, 'Done');
      debugPrint('Task marked as done!');
    } else {
      debugPrint('No action needed.');
    }
  }
}
