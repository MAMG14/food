import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/open_food_facts_mapping.dart';
import 'package:food/domain/validation.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/format/expiry_format.dart';
import 'package:food/ui/item/product_photo_preview.dart';
import 'package:food/ui/l10n_labels.dart';

/// Editable confirmation after an Open Food Facts match (spec 005).
class ProductConfirmPage extends StatefulWidget {
  const ProductConfirmPage({
    super.key,
    required this.repository,
    required this.reminders,
    required this.draft,
    required this.imageStore,
    this.onImageAttached,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;
  final OffProductDraft draft;
  final ProductImageStore imageStore;

  /// Called on the UI isolate after a successful local image attach.
  final VoidCallback? onImageAttached;

  @override
  State<ProductConfirmPage> createState() => _ProductConfirmPageState();
}

class _ProductConfirmPageState extends State<ProductConfirmPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  late ExpiryPrecision _precision;
  DateTime? _dayDate;
  DateTime? _monthDate;
  late Unit _unit;
  late Category _category;
  StorageLocation _location = StorageLocation.other;

  String? _nameError;
  String? _quantityError;
  String? _expiryError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _nameController = TextEditingController(text: d.name);
    _quantityController = TextEditingController(text: _formatQuantity(d.quantity));
    _notesController = TextEditingController();
    _unit = d.unit;
    _category = d.category;
    _precision = ExpiryPrecision.day;
    final now = DateTime.now();
    _dayDate = DateTime(now.year, now.month, now.day);
    _monthDate = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatQuantity(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  String get _expiryValue {
    if (_precision == ExpiryPrecision.day) {
      final d = _dayDate;
      if (d == null) return '';
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    }
    final d = _monthDate;
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}-$m';
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dayDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _dayDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantity = double.tryParse(
          _quantityController.text.trim().replaceAll(',', '.'),
        ) ??
        double.nan;

    final result = validateFoodItemInput(
      name: _nameController.text,
      quantity: quantity,
      expiryPrecision: _precision,
      expiryValue: _expiryValue,
    );

    setState(() {
      _nameError = null;
      _quantityError = null;
      _expiryError = null;
      for (final err in result.errors) {
        final message = err.code.label(l10n);
        switch (err.field) {
          case ValidationField.name:
            _nameError = message;
          case ValidationField.quantity:
            _quantityError = message;
          case ValidationField.expiry:
            _expiryError = message;
        }
      }
    });

    if (!result.isValid) return;

    setState(() => _saving = true);
    final notes = _notesController.text.trim();
    final item = await widget.repository.insert(
      FoodItem(
        name: _nameController.text.trim(),
        expiryPrecision: _precision,
        expiryValue: _expiryValue,
        quantity: quantity,
        unit: _unit,
        category: _category,
        notes: notes.isEmpty ? null : notes,
        location: _location,
        barcode: widget.draft.barcode,
        imagePath: null,
      ),
    );

    final url = widget.draft.imageUrl;
    if (url != null && url.isNotEmpty && item.id != null) {
      // Await so Home/edit see imagePath; failures are swallowed in the store.
      await widget.imageStore.downloadAndAttach(
        repository: widget.repository,
        itemId: item.id!,
        imageUrl: url,
        onAttached: widget.onImageAttached,
      );
    }

    unawaited(widget.reminders.resync());
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final imageUrl = widget.draft.imageUrl;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanConfirmTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ProductPhotoPreview(
              image: NetworkImage(imageUrl),
              aspectRatio: 1.2,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              errorText: _nameError,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text(l10n.fieldExpiry, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ExpiryPrecision>(
            segments: [
              ButtonSegment(
                value: ExpiryPrecision.day,
                label: Text(l10n.precisionDay),
              ),
              ButtonSegment(
                value: ExpiryPrecision.month,
                label: Text(l10n.precisionMonth),
              ),
            ],
            selected: {_precision},
            onSelectionChanged: (s) => setState(() => _precision = s.first),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _precision == ExpiryPrecision.day
                  ? (_dayDate == null
                      ? l10n.pickDate
                      : formatExpiry(
                          FoodItem(
                            name: '',
                            expiryPrecision: ExpiryPrecision.day,
                            expiryValue: _expiryValue,
                            quantity: 1,
                            unit: Unit.pz,
                            category: Category.other,
                            location: StorageLocation.other,
                          ),
                          locale,
                        ))
                  : (_monthDate == null
                      ? l10n.pickMonth
                      : formatYearMonth(_monthDate!, locale)),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _precision == ExpiryPrecision.day
                ? _pickDay
                : () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _monthDate ?? now,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 10),
                      helpText: l10n.pickMonth,
                    );
                    if (picked != null) {
                      setState(
                        () => _monthDate = DateTime(picked.year, picked.month),
                      );
                    }
                  },
          ),
          if (_expiryError != null)
            Text(
              _expiryError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.fieldQuantity,
              errorText: _quantityError,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Unit>(
            initialValue: _unit,
            decoration: InputDecoration(labelText: l10n.fieldUnit),
            items: [
              for (final u in Unit.values)
                DropdownMenuItem(value: u, child: Text(u.label(l10n))),
            ],
            onChanged: (u) {
              if (u != null) setState(() => _unit = u);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Category>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.fieldCategory),
            items: [
              for (final c in Category.values)
                DropdownMenuItem(value: c, child: Text(c.label(l10n))),
            ],
            onChanged: (c) {
              if (c != null) setState(() => _category = c);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StorageLocation>(
            initialValue: _location,
            decoration: InputDecoration(labelText: l10n.fieldLocation),
            items: [
              for (final loc in StorageLocation.values)
                DropdownMenuItem(value: loc, child: Text(loc.label(l10n))),
            ],
            onChanged: (loc) {
              if (loc != null) setState(() => _location = loc);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.fieldNotes),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : () => unawaited(_save()),
            child: Text(l10n.scanSave),
          ),
        ],
      ),
    );
  }
}
