/// Text of one reminder notification.
class ReminderMessage {
  const ReminderMessage({
    required this.id,
    required this.title,
    required this.body,
    this.lines = const [],
  });

  final int id;
  final String title;
  final String body;

  /// One line per item for expandable grouped notifications; empty if single.
  final List<String> lines;
}

/// Minimal surface over the OS notification system, so reminder logic can be
/// tested without platform plugins.
abstract interface class NotificationGateway {
  Future<void> init();

  /// Re-reads the device time zone (it may change while the app is alive).
  Future<void> refreshTimeZone();

  Future<bool> requestPermission();

  Future<bool> areEnabled();

  Future<void> openSystemSettings();

  Future<void> cancelAll();

  /// [fireAt] is local wall-clock time.
  Future<void> schedule(ReminderMessage message, DateTime fireAt);

  Future<void> showNow(ReminderMessage message);

  /// Emits when the user taps a reminder while the app is running.
  Stream<void> get taps;

  /// Whether this app launch was caused by tapping a reminder.
  Future<bool> launchedFromNotification();
}
