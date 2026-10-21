import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/validation.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/format/expiry_format.dart';
import 'package:food/ui/item/product_photo_preview.dart';
import 'package:food/ui/l10n_labels.dart';
import 'package:image_picker/image_picker.dart';

class FoodItemFormPage extends StatefulWidget {
  const FoodItemFormPage({
    super.key,
    required this.repository,
    this.item,
    this.imageStore,
    this.pickImage,
  });

  final FoodItemRepository repository;
  final FoodItem? item;
  final ProductImageStore? imageStore;

  /// Test seam: returns a local file path, or null if cancelled / denied.
  final Future<String?> Function(ImageSource source)? pickImage;

  @override
  State<FoodItemFormPage> createState() => _FoodItemFormPageState();
}

class _FoodItemFormPageState extends State<FoodItemFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late final ProductImageStore _imageStore;
  late final bool _ownsImageStore;
  final _picker = ImagePicker();

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

  /// Fresh row from DB (includes `imagePath` after async download).
  FoodItem? _persisted;

  /// Staging path chosen this session (camera/gallery).
  String? _pendingImagePath;

  /// User asked to clear the photo on save.
  var _removeImage = false;

  /// Decoded preview bytes ([MemoryImage] avoids FileImage hangs in tests).
  Uint8List? _previewBytes;

  bool get _isEditing => widget.item != null;

  String? get _displayImagePath {
    if (_removeImage) return null;
    return _pendingImagePath ?? _persisted?.imagePath ?? widget.item?.imagePath;
  }

  Future<void> _loadPreviewBytes(String? path) async {
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _previewBytes = null);
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      setState(() => _previewBytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _previewBytes = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsImageStore = widget.imageStore == null;
    _imageStore = widget.imageStore ?? ProductImageStore();
    final item = widget.item;
    _persisted = item;
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
      unawaited(_reloadPersisted());
      unawaited(_loadPreviewBytes(item.imagePath));
    } else {
      final now = DateTime.now();
      _dayDate = DateTime(now.year, now.month, now.day);
      _monthDate = DateTime(now.year, now.month);
    }
  }

  Future<void> _reloadPersisted() async {
    final id = widget.item?.id;
    if (id == null) return;
    final fresh = await widget.repository.getById(id);
    if (!mounted || fresh == null) return;
    setState(() => _persisted = fresh);
    if (_pendingImagePath == null && !_removeImage) {
      unawaited(_loadPreviewBytes(fresh.imagePath));
    }
  }

  Future<void> _cleanupStaging() async {
    final pending = _pendingImagePath;
    _pendingImagePath = null;
    await _imageStore.deleteIfExists(pending);
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
    unawaited(_cleanupStaging());
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    if (_ownsImageStore) {
      _imageStore.close();
    }
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

  Future<String?> _defaultPick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }

  Future<void> _choosePhotoSource({required bool replacing}) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.productImageCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.productImageGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final pick = widget.pickImage ?? _defaultPick;
    String? path;
    try {
      path = await pick(source);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productImagePermissionDenied)),
      );
      return;
    }
    if (!mounted || path == null) return;

    final previousPending = _pendingImagePath;
    final staged = await _imageStore.stageFile(path);
    if (!mounted) return;
    if (staged == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productImagePermissionDenied)),
      );
      return;
    }

    await _imageStore.deleteIfExists(previousPending);
    setState(() {
      _pendingImagePath = staged;
      _removeImage = false;
    });
    unawaited(_loadPreviewBytes(staged));
  }

  void _removePhoto() {
    unawaited(_cleanupStaging());
    setState(() {
      _removeImage = true;
      _pendingImagePath = null;
      _previewBytes = null;
    });
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
    // Preserve existing path unless removing; pending attach happens after persist.
    final keptPath = _removeImage
        ? null
        : (_persisted?.imagePath ?? widget.item?.imagePath);
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
      barcode: _persisted?.barcode ?? widget.item?.barcode,
      imagePath: keptPath,
    );

    try {
      late final FoodItem saved;
      if (_isEditing) {
        saved = await widget.repository.update(draft);
        final id = saved.id!;
        if (_removeImage) {
          await _imageStore.clearAttached(
            repository: widget.repository,
            itemId: id,
          );
        } else if (_pendingImagePath != null) {
          await _imageStore.attachFromFile(
            repository: widget.repository,
            itemId: id,
            sourcePath: _pendingImagePath!,
          );
          _pendingImagePath = null;
        }
      } else {
        saved = await widget.repository.insert(draft);
        final id = saved.id;
        if (id != null && _pendingImagePath != null) {
          await _imageStore.attachFromFile(
            repository: widget.repository,
            itemId: id,
            sourcePath: _pendingImagePath!,
          );
          _pendingImagePath = null;
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
      await _cleanupStaging();
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
    final hasPhoto = _previewBytes != null && _previewBytes!.isNotEmpty;

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
          if (hasPhoto) ...[
            ProductPhotoPreview(
              image: MemoryImage(_previewBytes!),
              aspectRatio: 1.4,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => unawaited(_choosePhotoSource(replacing: true)),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.productImageReplace),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : _removePhoto,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.productImageRemove),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            // Show replace/remove when path exists but bytes not loaded yet,
            // or add when there is no photo.
            if (_displayImagePath != null && !_removeImage) ...[
              // Bytes still loading; avoid indeterminate progress (hangs tests).
              const SizedBox(height: 8),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => unawaited(_choosePhotoSource(replacing: false)),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.productImageAdd),
              ),
              const SizedBox(height: 16),
            ],
          ],
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
            onPressed: _saving ? null : () => unawaited(_save()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
