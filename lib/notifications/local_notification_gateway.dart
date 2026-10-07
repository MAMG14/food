import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_gateway.dart';

/// [NotificationGateway] backed by `flutter_local_notifications`.
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({
    required this.channelName,
    required this.channelDescription,
  });

  /// Shown in the Android system notification settings; must be localized.
  final String channelName;
  final String channelDescription;

  static const _channelId = 'expiry_reminders';

  /// Monochrome vector also used by the splash (Android small icon).
  static const _androidIcon = 'splash_mark';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<void>.broadcast();

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    await refreshTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidIcon),
        // Permission is requested explicitly on first launch (spec 003 RF-17).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _taps.add(null),
    );
  }

  @override
  Future<void> refreshTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Could not resolve device time zone: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true, badge: true) ??
        false;
  }

  @override
  Future<bool> areEnabled() async {
    final android = _android;
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    return (await _ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<void> openSystemSettings() async {
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(ReminderMessage message, DateTime fireAt) {
    return _plugin.zonedSchedule(
      id: message.id,
      scheduledDate: tz.TZDateTime(
        tz.local,
        fireAt.year,
        fireAt.month,
        fireAt.day,
        fireAt.hour,
        fireAt.minute,
      ),
      notificationDetails: _details(message),
      // Inexact avoids the exact-alarm permission; minutes of drift are fine.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: message.title,
      body: message.body,
    );
  }

  @override
  Future<void> showNow(ReminderMessage message) {
    return _plugin.show(
      id: message.id,
      title: message.title,
      body: message.body,
      notificationDetails: _details(message),
    );
  }

  @override
  Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  NotificationDetails _details(ReminderMessage message) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDescription,
        styleInformation: message.lines.isEmpty
            ? BigTextStyleInformation(message.body)
            : InboxStyleInformation(message.lines, contentTitle: message.title),
      ),
      iOS: const DarwinNotificationDetails(threadIdentifier: _channelId),
    );
  }
}
