import 'enums.dart';

/// Lead times (days before effective expiry) the user can pick (spec 003).
const List<int> allowedLeadDays = [0, 1, 2, 3, 5, 7, 10, 14, 21, 30];

bool isAllowedLeadDays(int days) => allowedLeadDays.contains(days);

/// How a category behaves regarding reminders.
enum ReminderRuleMode {
  /// Follow [ReminderSettings.generalLeadDays].
  general,

  /// Own lead time in [CategoryReminderRule.leadDays].
  custom,

  /// Never remind for this category.
  off,
}

/// Per-category reminder rule.
class CategoryReminderRule {
  const CategoryReminderRule.useGeneral()
    : mode = ReminderRuleMode.general,
      leadDays = null;

  const CategoryReminderRule.custom(int this.leadDays)
    : mode = ReminderRuleMode.custom;

  const CategoryReminderRule.off()
    : mode = ReminderRuleMode.off,
      leadDays = null;

  final ReminderRuleMode mode;

  /// Only set when [mode] is [ReminderRuleMode.custom].
  final int? leadDays;

  @override
  bool operator ==(Object other) =>
      other is CategoryReminderRule &&
      other.mode == mode &&
      other.leadDays == leadDays;

  @override
  int get hashCode => Object.hash(mode, leadDays);

  @override
  String toString() => 'CategoryReminderRule($mode, $leadDays)';
}

/// User configuration for expiry reminders (spec 003).
class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.generalLeadDays,
    required this.notifyHour,
    required this.notifyMinute,
    this.categoryRules = const {},
    this.permissionAsked = false,
  });

  static const defaults = ReminderSettings(
    enabled: true,
    generalLeadDays: 2,
    notifyHour: 9,
    notifyMinute: 0,
  );

  final bool enabled;

  final int generalLeadDays;

  /// Local time of day when reminders fire (0–23 / 0–59).
  final int notifyHour;
  final int notifyMinute;

  /// Categories missing from the map use the general rule.
  final Map<Category, CategoryReminderRule> categoryRules;

  /// Whether the OS notification permission was already requested once.
  final bool permissionAsked;

  CategoryReminderRule ruleFor(Category category) =>
      categoryRules[category] ?? const CategoryReminderRule.useGeneral();

  ReminderSettings withRule(Category category, CategoryReminderRule rule) {
    final rules = Map<Category, CategoryReminderRule>.of(categoryRules);
    if (rule.mode == ReminderRuleMode.general) {
      rules.remove(category);
    } else {
      rules[category] = rule;
    }
    return copyWith(categoryRules: rules);
  }

  ReminderSettings copyWith({
    bool? enabled,
    int? generalLeadDays,
    int? notifyHour,
    int? notifyMinute,
    Map<Category, CategoryReminderRule>? categoryRules,
    bool? permissionAsked,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      generalLeadDays: generalLeadDays ?? this.generalLeadDays,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      categoryRules: categoryRules ?? this.categoryRules,
      permissionAsked: permissionAsked ?? this.permissionAsked,
    );
  }
}
