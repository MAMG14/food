import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/domain/expiry.dart';
import 'package:food/domain/home_filter.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/urgency.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/home/food_item_tile.dart';
import 'package:food/ui/item/food_item_form_page.dart';
import 'package:food/ui/settings/reminder_settings_page.dart';
import 'package:food/ui/theme/food_theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.repository,
    required this.reminders,
    required this.reminderFilter,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;

  /// Reminder tap sets [HomeFilter.soon].
  final ValueNotifier<HomeFilter?> reminderFilter;

  @override
  InventoryPageState createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> {
  HomeFilter _filter = HomeFilter.optimal;
  SortMode _sortMode = SortMode.expiry;
  List<FoodItem> _items = [];
  HomeFilterCounts _counts = const HomeFilterCounts(
    optimal: 0,
    soon: 0,
    expired: 0,
  );
  bool _loading = true;
  late DateTime _today;
  var _filterInitialized = false;

  @override
  void initState() {
    super.initState();
    _today = dateOnly(DateTime.now());
    widget.reminderFilter.addListener(_onReminderFilter);
    unawaited(reload());
  }

  @override
  void dispose() {
    widget.reminderFilter.removeListener(_onReminderFilter);
    super.dispose();
  }

  void _onReminderFilter() {
    final pending = widget.reminderFilter.value;
    if (pending == null) return;
    setState(() => _filter = pending);
    widget.reminderFilter.value = null;
    unawaited(reload());
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    _today = dateOnly(DateTime.now());
    final all = await widget.repository.getAll();
    final counts = countByHomeFilter(all, _today);
    if (!_filterInitialized) {
      _filter = defaultHomeFilter(counts);
      _filterInitialized = true;
    }
    final filtered = itemsForHomeFilter(all, _filter, _today);
    final sorted = sortItems(filtered, _sortMode, _today);
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _items = sorted;
      _loading = false;
    });
  }

  Future<void> _openReminderSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReminderSettingsPage(reminders: widget.reminders),
      ),
    );
  }

  Future<void> _openForm({FoodItem? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodItemFormPage(
          repository: widget.repository,
          item: item,
        ),
      ),
    );
    if (changed == true && mounted) {
      unawaited(widget.reminders.resync());
      await reload();
    }
  }

  void _selectFilter(HomeFilter filter) {
    setState(() => _filter = filter);
    unawaited(reload());
  }

  String _emptyMessage(AppLocalizations l10n) {
    return switch (_filter) {
      HomeFilter.optimal => l10n.emptyActive,
      HomeFilter.soon => l10n.emptySoon,
      HomeFilter.expired => l10n.emptyExpired,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: _openReminderSettings,
            tooltip: l10n.reminderSettingsTitle,
            icon: const Icon(Icons.settings_outlined),
          ),
          PopupMenuButton<SortMode>(
            initialValue: _sortMode,
            tooltip: l10n.sortByExpiry,
            onSelected: (mode) {
              setState(() => _sortMode = mode);
              unawaited(reload());
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortMode.name,
                child: Text(l10n.sortByName),
              ),
              PopupMenuItem(
                value: SortMode.expiry,
                child: Text(l10n.sortByExpiry),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterCard(
                    label: l10n.filterOptimal,
                    count: _counts.optimal,
                    selected: _filter == HomeFilter.optimal,
                    accent: urgencyForeground(scheme, ExpiryUrgency.normal),
                    onTap: () => _selectFilter(HomeFilter.optimal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterCard(
                    label: l10n.filterSoon,
                    count: _counts.soon,
                    selected: _filter == HomeFilter.soon,
                    accent: urgencyForeground(scheme, ExpiryUrgency.high),
                    onTap: () => _selectFilter(HomeFilter.soon),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterCard(
                    label: l10n.filterExpired,
                    count: _counts.expired,
                    selected: _filter == HomeFilter.expired,
                    accent: urgencyForeground(scheme, ExpiryUrgency.critical),
                    onTap: () => _selectFilter(HomeFilter.expired),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: scheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _emptyMessage(l10n),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return FoodItemTile(
                              item: item,
                              today: _today,
                              onTap: () => _openForm(item: item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? accent : scheme.outlineVariant;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                l10n.productsCount(count),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
