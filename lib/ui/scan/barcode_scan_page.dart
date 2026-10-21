import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/open_food_facts_mapping.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/open_food_facts/off_api_client.dart';
import 'package:food/open_food_facts/off_product.dart';
import 'package:food/ui/item/food_item_form_page.dart';
import 'package:food/ui/scan/product_confirm_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera barcode scan → Open Food Facts lookup (spec 005).
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({
    super.key,
    required this.repository,
    required this.reminders,
    this.offClient,
    this.imageStore,
    this.onImageAttached,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;
  final OffApiClient? offClient;
  final ProductImageStore? imageStore;

  /// Fired when a product image finished downloading (refresh Home).
  final VoidCallback? onImageAttached;

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  late final OffApiClient _offClient;
  late final ProductImageStore _imageStore;
  late final bool _ownsOffClient;

  var _lookupInFlight = false;
  var _cameraDenied = false;

  @override
  void initState() {
    super.initState();
    _ownsOffClient = widget.offClient == null;
    _offClient = widget.offClient ?? OffApiClient();
    // Prefer a long-lived store from [HomeShell]; never close it here.
    _imageStore = widget.imageStore ?? ProductImageStore();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsOffClient) {
      _offClient.close();
    }
    super.dispose();
  }

  Future<void> _openManual({String? message}) async {
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodItemFormPage(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_lookupInFlight) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    setState(() => _lookupInFlight = true);
    await _controller.stop();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final result = await _offClient.fetchByBarcode(raw);
    if (!mounted) return;

    switch (result) {
      case OffLookupMatch(:final product):
        final draft = offProductToDraft(
          OffProductInput(
            productName: product.productName,
            brands: product.brands,
            quantity: product.quantity,
            categoriesTags: product.categoriesTags,
            imageUrl: product.imageFrontUrl,
            barcode: product.code,
          ),
        );
        if (draft == null) {
          setState(() => _lookupInFlight = false);
          await _controller.start();
          await _openManual(message: l10n.scanNotFound);
          return;
        }
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProductConfirmPage(
              repository: widget.repository,
              reminders: widget.reminders,
              draft: draft,
              imageStore: _imageStore,
              onImageAttached: widget.onImageAttached,
            ),
          ),
        );
        if (!mounted) return;
        if (changed == true) {
          Navigator.of(context).pop(true);
          return;
        }
        setState(() => _lookupInFlight = false);
        await _controller.start();
      case OffLookupNotFound():
        setState(() => _lookupInFlight = false);
        await _controller.start();
        await _openManual(message: l10n.scanNotFound);
      case OffLookupFailure():
        setState(() => _lookupInFlight = false);
        await _controller.start();
        await _openManual(message: l10n.scanNetworkError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: _cameraDenied
          ? _DeniedBody(onManual: () => unawaited(_openManual()))
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_cameraDenied) {
                        setState(() => _cameraDenied = true);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
                if (_lookupInFlight)
                  ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.scanLookingUp,
                            style: TextStyle(color: scheme.onInverseSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: FilledButton.tonal(
                        onPressed: _lookupInFlight
                            ? null
                            : () => unawaited(_openManual()),
                        child: Text(l10n.scanRegisterManual),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DeniedBody extends StatelessWidget {
  const _DeniedBody({required this.onManual});

  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.scanCameraDeniedTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.scanCameraDeniedBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onManual,
            child: Text(l10n.scanRegisterManual),
          ),
        ],
      ),
    );
  }
}
