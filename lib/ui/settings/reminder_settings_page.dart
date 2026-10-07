import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/l10n_labels.dart';

/// Reminder configuration (spec 003 RF-1–5, RF-18). Changes save instantly.
class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key, required this.reminders});

  final ReminderScheduler reminders;

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  ReminderSettings? _settings;
  bool _permissionGranted = true;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Returning from the system settings may have changed the permission.
    _lifecycle = AppLifecycleListener(onResume: _checkPermission);
    _load();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await widget.reminders.settings.load();
    if (!mounted) return;
    setState(() => _settings = settings);
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await widget.reminders.gateway.areEnabled();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
  }

  Future<void> _update(ReminderSettings next) async {
    setState(() => _settings = next);
    await widget.reminders.settings.save(next);
    unawaited(widget.reminders.resync());
  }

  Future<void> _pickTime(ReminderSettings s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.notifyHour, minute: s.notifyMinute),
    );
    if (picked == null) return;
    await _update(s.copyWith(notifyHour: picked.hour, notifyMinute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = _settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminderSettingsTitle)),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (!_permissionGranted) ...[
                  _PermissionBanner(
                    onOpenSettings: widget.reminders.gateway.openSystemSettings,
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: Text(l10n.reminderEnabled),
                    subtitle: Text(l10n.reminderEnabledHint),
                    value: s.enabled,
                    onChanged: (v) => _update(s.copyWith(enabled: v)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: s.generalLeadDays,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.reminderGeneralLead),
                  items: [
                    for (final d in allowedLeadDays)
                      DropdownMenuItem(value: d, child: Text(_leadLabel(l10n, d))),
                  ],
                  onChanged: s.enabled
                      ? (d) => _update(s.copyWith(generalLeadDays: d))
                      : null,
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    enabled: s.enabled,
                    title: Text(l10n.reminderNotifyAt),
                    trailing: Text(
                      TimeOfDay(hour: s.notifyHour, minute: s.notifyMinute)
                          .format(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => _pickTime(s),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.reminderByCategory,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reminderByCategoryHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final category in Category.values) ...[
                  DropdownButtonFormField<CategoryReminderRule>(
                    // Rebuild when the general lead changes its label.
                    key: ValueKey('$category-${s.generalLeadDays}'),
                    initialValue: s.ruleFor(category),
                    isExpanded: true,
                    decoration: InputDecoration(labelText: category.label(l10n)),
                    items: [
                      DropdownMenuItem(
                        value: const CategoryReminderRule.useGeneral(),
                        child: Text(
                          l10n.reminderRuleGeneral(_leadLabel(l10n, s.generalLeadDays)),
                        ),
                      ),
                      for (final d in allowedLeadDays)
                        DropdownMenuItem(
                          value: CategoryReminderRule.custom(d),
                          child: Text(_leadLabel(l10n, d)),
                        ),
                      DropdownMenuItem(
                        value: const CategoryReminderRule.off(),
                        child: Text(l10n.reminderRuleOff),
                      ),
                    ],
                    onChanged: s.enabled
                        ? (rule) {
                            if (rule != null) _update(s.withRule(category, rule));
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

String _leadLabel(AppLocalizations l10n, int days) =>
    days == 0 ? l10n.reminderLeadSameDay : l10n.reminderLeadDays(days);

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onOpenSettings});

  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_off_outlined, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.reminderPermissionDenied,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(l10n.reminderOpenSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
