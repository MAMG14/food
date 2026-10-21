import 'package:flutter/material.dart';
import 'package:food/l10n/app_localizations.dart';

/// Tappable product photo that opens a pinch-zoom fullscreen view.
class ProductPhotoPreview extends StatelessWidget {
  const ProductPhotoPreview({
    super.key,
    required this.image,
    this.aspectRatio = 1.2,
  });

  final ImageProvider image;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openFullscreenProductImage(context, image),
        child: Semantics(
          button: true,
          label: l10n.productImageOpen,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen dark viewer with pinch-to-zoom ([InteractiveViewer]).
void openFullscreenProductImage(BuildContext context, ImageProvider image) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _FullscreenProductImagePage(image: image),
    ),
  );
}

class _FullscreenProductImagePage extends StatelessWidget {
  const _FullscreenProductImagePage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            // Child must fill the viewport so the photo scales up (not intrinsic px).
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Image(
                image: image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                tooltip: closeLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
