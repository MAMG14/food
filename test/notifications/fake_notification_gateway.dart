import 'dart:async';

import 'package:food/notifications/notification_gateway.dart';

/// Records what the scheduler asks the OS to do.
class FakeNotificationGateway implements NotificationGateway {
  final scheduled = <int, (ReminderMessage, DateTime)>{};
  final shownNow = <ReminderMessage>[];
  int cancelAllCalls = 0;
  int permissionRequests = 0;
  bool enabled = true;
  bool grantOnRequest = true;
  bool launchedByTap = false;
  int settingsOpened = 0;
  final tapController = StreamController<void>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<void> refreshTimeZone() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(ReminderMessage message, DateTime fireAt) async {
    scheduled[message.id] = (message, fireAt);
  }

  @override
  Future<void> showNow(ReminderMessage message) async => shownNow.add(message);

  @override
  Stream<void> get taps => tapController.stream;

  @override
  Future<bool> launchedFromNotification() async => launchedByTap;
}
