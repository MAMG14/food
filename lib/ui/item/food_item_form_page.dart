import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/validation.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/format/expiry_format.dart';
import 'package:food/ui/l10n_labels.dart';

class FoodItemFormPage extends StatefulWidget {
  const FoodItemFormPage({
    super.key,
    required this.repository,
    this.item,
  });

  final FoodItemRepository repository;
  final FoodItem? item;

  @override
  State<FoodItemFormPage> createState() => _FoodItemFormPageState();
}

class _FoodItemFormPageState extends State<FoodItemFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  late ExpiryPrecision _precision;
  DateTime? _dayDate;
  DateTime? _monthDate;
  Unit _unit = Unit.pz;
  Category _category = Category.other;
  StorageLocation _location = StorageLocation.other;

  String? _nameError;
  String? _quantityError;
  String? _expiryError;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item != null ? _formatQuantity(item.quantity) : '1',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _precision = item?.expiryPrecision ?? ExpiryPrecision.day;
    _unit = item?.unit ?? Unit.pz;
    _category = item?.category ?? Category.other;
    _location = item?.location ?? StorageLocation.other;

    if (item != null) {
      _applyExpiryValue(item.expiryPrecision, item.expiryValue);
    } else {
      final now = DateTime.now();
      _dayDate = DateTime(now.year, now.month, now.day);
      _monthDate = DateTime(now.year, now.month);
    }
  }

  void _applyExpiryValue(ExpiryPrecision precision, String value) {
    if (precision == ExpiryPrecision.day) {
      final parts = value.split('-');
      if (parts.length == 3) {
        _dayDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } else {
      final parts = value.split('-');
      if (parts.length == 2) {
        _monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _pickMonth() async {
    final initial = _monthDate ?? DateTime.now();
    var selectedYear = initial.year;
    var selectedMonth = initial.month;

    final confirmed = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(l10n.pickMonth),
              content: Row(
                children: [
                  IconButton(
                    onPressed: () => setLocal(() => selectedYear--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$selectedYear'),
                  IconButton(
                    onPressed: () => setLocal(() => selectedYear++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedMonth,
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                      ],
                      onChanged: (m) {
                        if (m == null) return;
                        setLocal(() => selectedMonth = m);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(selectedYear, selectedMonth),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != null) {
      setState(() => _monthDate = DateTime(confirmed.year, confirmed.month));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final quantity = double.tryParse(_quantityController.text.trim().replaceAll(',', '.')) ??
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
    final draft = FoodItem(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      expiryPrecision: _precision,
      expiryValue: _expiryValue,
      quantity: quantity,
      unit: _unit,
      category: _category,
      notes: notes.isEmpty ? null : notes,
      location: _location,
    );

    if (_isEditing) {
      await widget.repository.update(draft);
    } else {
      await widget.repository.insert(draft);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final id = widget.item?.id;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      await widget.repository.delete(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final textTheme = Theme.of(context).textTheme;

    Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editItem : l10n.addItem),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          sectionTitle(l10n.sectionIdentity),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              errorText: _nameError,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          sectionTitle(l10n.sectionExpiry),
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
            onSelectionChanged: (values) {
              setState(() => _precision = values.first);
            },
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: _precision == ExpiryPrecision.day
                ? ListTile(
                    title: Text(
                      _dayDate == null
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
                            ),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDay,
                  )
                : ListTile(
                    title: Text(
                      _monthDate == null
                          ? l10n.pickMonth
                          : formatYearMonth(_monthDate!, locale),
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _pickMonth,
                  ),
          ),
          if (_expiryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _expiryError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          sectionTitle(l10n.sectionQuantity),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: l10n.fieldQuantity,
              errorText: _quantityError,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Unit>(
            // ignore: deprecated_member_use
            value: _unit,
            decoration: InputDecoration(labelText: l10n.fieldUnit),
            items: [
              for (final u in Unit.values)
                DropdownMenuItem(value: u, child: Text(u.label(l10n))),
            ],
            onChanged: (u) {
              if (u != null) setState(() => _unit = u);
            },
          ),
          const SizedBox(height: 16),
          sectionTitle(l10n.sectionDetails),
          DropdownButtonFormField<Category>(
            // ignore: deprecated_member_use
            value: _category,
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
            // ignore: deprecated_member_use
            value: _location,
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
            maxLines: 3,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
