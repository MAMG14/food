import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/domain/expiry.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/home/food_item_tile.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/item/food_item_form_page.dart';
import 'package:food/ui/settings/reminder_settings_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.repository,
    required this.reminders,
    required this.showActive,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;

  /// Notifies when the inventory must switch to Active (reminder tapped).
  final Listenable showActive;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  InventoryView _view = InventoryView.active;
  SortMode _sortMode = SortMode.expiry;
  List<FoodItem> _items = [];
  bool _loading = true;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = dateOnly(DateTime.now());
    widget.showActive.addListener(_onShowActive);
    _reload();
  }

  @override
  void dispose() {
    widget.showActive.removeListener(_onShowActive);
    super.dispose();
  }

  void _onShowActive() {
    setState(() => _view = InventoryView.active);
    _reload();
  }

  Future<void> _openReminderSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReminderSettingsPage(reminders: widget.reminders),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _today = dateOnly(DateTime.now());
    final all = await widget.repository.getAll();
    final filtered = filterByView(all, _view, _today);
    final sorted = sortItems(filtered, _sortMode, _today);
    if (!mounted) return;
    setState(() {
      _items = sorted;
      _loading = false;
    });
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
      await _reload();
    }
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
            icon: const Icon(Icons.notifications_outlined),
          ),
          PopupMenuButton<SortMode>(
            initialValue: _sortMode,
            tooltip: l10n.sortByExpiry,
            onSelected: (mode) {
              setState(() => _sortMode = mode);
              _reload();
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<InventoryView>(
                segments: [
                  ButtonSegment(
                    value: InventoryView.active,
                    label: Text(l10n.tabActive),
                    icon: const Icon(Icons.kitchen_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: InventoryView.expired,
                    label: Text(l10n.tabExpired),
                    icon: const Icon(Icons.event_busy_outlined, size: 18),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (values) {
                  setState(() => _view = values.first);
                  _reload();
                },
              ),
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
                                _view == InventoryView.active
                                    ? Icons.inventory_2_outlined
                                    : Icons.check_circle_outline,
                                size: 56,
                                color: scheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _view == InventoryView.active
                                    ? l10n.emptyActive
                                    : l10n.emptyExpired,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              if (_view == InventoryView.active) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.emptyActiveHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 88),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        tooltip: l10n.addItem,
        icon: const Icon(Icons.add),
        label: Text(l10n.addItem),
      ),
    );
  }
}
