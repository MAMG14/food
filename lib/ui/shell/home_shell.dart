import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/domain/home_filter.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/home/inventory_page.dart';
import 'package:food/ui/item/food_item_form_page.dart';

/// Bottom navigation: Home + Add (spec 004).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.reminders,
    required this.reminderFilter,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;

  /// When a reminder is tapped, value becomes [HomeFilter.soon].
  final ValueNotifier<HomeFilter?> reminderFilter;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tabIndex = 0;
  final _inventoryKey = GlobalKey<InventoryPageState>();

  Future<void> _openAdd() async {
    setState(() => _tabIndex = 1);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodItemFormPage(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    setState(() => _tabIndex = 0);
    if (changed == true) {
      unawaited(widget.reminders.resync());
      await _inventoryKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Single Scaffold (inside InventoryPage) so AppBar paints behind the
    // status bar and NavigationBar respects the nav inset under edge-to-edge.
    return InventoryPage(
      key: _inventoryKey,
      repository: widget.repository,
      reminders: widget.reminders,
      reminderFilter: widget.reminderFilter,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            unawaited(_openAdd());
            return;
          }
          setState(() => _tabIndex = 0);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.navAdd,
          ),
        ],
      ),
    );
  }
}
