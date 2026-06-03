import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Handles both FCM (from server) and local scheduled notifications.
/// Dev 3 (Holiday API) should call [cancelTodayReminderIfHoliday] after
/// their holiday check resolves.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const _channelId = 'mbg_daily_reminder';
  static const _channelName = 'Pengingat Laporan Harian';
  static const _reminderNotifId = 1001;

  // ─── Init ─────────────────────────────────────────────────

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannel();
    await _setupFCM();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pengingat untuk mengisi laporan distribusi harian MBG',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─── FCM ─────────────────────────────────────────────────

  Future<void> _setupFCM() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Show FCM notifications while app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  /// Returns the device FCM token — save this to Firestore on login.
  Future<String?> getToken() => _fcm.getToken();

  // ─── Local scheduled reminder ─────────────────────────────

  /// Schedule a daily reminder at 13:00 WIB.
  /// Call this once after the user logs in.
  /// Dev 3: call [cancelTodayReminderIfHoliday] after holiday check.
  Future<void> scheduleDailyReminder() async {
    await _localNotif.zonedSchedule(
      _reminderNotifId,
      'Pengingat Laporan Harian 📋',
      'Jangan lupa isi laporan distribusi MBG hari ini!',
      _nextInstanceOf(13, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel today's reminder — called by Dev 3 when isHoliday == true.
  Future<void> cancelTodayReminderIfHoliday(bool isHoliday) async {
    if (isHoliday) {
      await _localNotif.cancel(_reminderNotifId);
    }
  }

  /// Cancel the daily reminder notification.
  Future<void> cancelReminder() => _localNotif.cancel(_reminderNotifId);

  /// Cancel all local notifications (e.g. on logout).
  Future<void> cancelAll() => _localNotif.cancelAll();

  // ─── Status notifications (triggered by admin actions) ────

  Future<void> showVerifiedNotification(String kitchenName) async {
    await _localNotif.show(
      1002,
      'Laporan Diverifikasi ✅',
      'Laporan $kitchenName telah diverifikasi oleh admin.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  Future<void> showRejectedNotification(
      String kitchenName, String reason) async {
    await _localNotif.show(
      1003,
      'Laporan Ditolak ❌',
      'Laporan $kitchenName ditolak: $reason',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: navigate to relevant screen based on response.payload
  }
}
