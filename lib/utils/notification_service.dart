/// Local notification service for scheduled wishlist reminders.
///
/// Wraps `flutter_local_notifications` to schedule a reminder at a
/// chosen future date/time. Permissions are requested on first use.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Initialises the plugin, timezone data, and default channels.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // Request Android 13+ POST_NOTIFICATIONS permission.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Requests notification permissions (iOS + Android 13+).
  Future<bool> requestPermissions() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  /// Schedules a reminder notification for [spotName] at [scheduledTime].
  ///
  /// [id] should be unique per reminder; using the spot's database id is
  /// recommended so duplicates can be cancelled later.
  Future<void> scheduleReminder({
    required int id,
    required String spotName,
    required DateTime scheduledTime,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id,
      'Pengingat SpotSaku',
      'Saatnya mengunjungi "$spotName"!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spotsaku_reminders',
          'Pengingat Wishlist',
          channelDescription: 'Reminder untuk spot yang belum dikunjungi.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a previously scheduled reminder by id.
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }
}
