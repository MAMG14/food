import 'dart:io';

import 'package:food/data/food_item_repository.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local product image files under the app documents directory.
///
/// Contract (spec 005): insert item with `imagePath == null`, then
/// [downloadAndAttach] — update path only if the item still exists.
/// Manual photos: [attachFromFile] / [clearAttached]; staging via [stageFile].
class ProductImageStore {
  ProductImageStore({
    this.documentsDirectory,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Override for tests (temp directory).
  final Directory? Function()? documentsDirectory;

  final http.Client _http;

  static const _userAgent = 'AlacenaBunker/1.0 (Flutter)';

  Future<Directory> _root() async {
    final override = documentsDirectory?.call();
    if (override != null) {
      if (!override.existsSync()) {
        await override.create(recursive: true);
      }
      return override;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'product_images'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _stagingRoot() async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'staging'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Absolute path where an item's image would be stored.
  Future<String> pathForItem(int itemId) async {
    final root = await _root();
    return p.join(root.path, 'item_$itemId.jpg');
  }

  /// Deletes [path] if it exists; no-op if null or missing.
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Copies [sourcePath] into a staging file for the form session.
  ///
  /// Caller must [deleteIfExists] on cancel (pop without save).
  Future<String?> stageFile(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      final staging = await _stagingRoot();
      final dest = p.join(
        staging.path,
        'pending_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await source.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  /// Copies a local file onto the item and sets `image_path` if the row exists.
  ///
  /// Replaces any previous file. Does not throw to the UI caller.
  Future<String?> attachFromFile({
    required FoodItemRepository repository,
    required int itemId,
    required String sourcePath,
  }) async {
    try {
      final existing = await repository.getById(itemId);
      if (existing == null) return null;

      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final path = await pathForItem(itemId);
      final partPath = '$path.part';
      await source.copy(partPath);

      if (await repository.getById(itemId) == null) {
        await deleteIfExists(partPath);
        return null;
      }

      // Drop previous final image if different path.
      if (existing.imagePath != null &&
          existing.imagePath != path &&
          existing.imagePath != sourcePath) {
        await deleteIfExists(existing.imagePath);
      }

      final finalFile = File(path);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await File(partPath).rename(path);
      await repository.updateImagePath(itemId, path);

      final staging = await _stagingRoot();
      if (p.isWithin(staging.path, sourcePath)) {
        await deleteIfExists(sourcePath);
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Deletes the local file and clears `image_path` if the row exists.
  Future<void> clearAttached({
    required FoodItemRepository repository,
    required int itemId,
  }) async {
    try {
      final existing = await repository.getById(itemId);
      if (existing == null) return;
      await deleteIfExists(existing.imagePath);
      await repository.updateImagePath(itemId, null);
    } catch (_) {
      // Spec: failure must not block UI.
    }
  }

  /// Downloads [imageUrl] and sets `image_path` on [itemId] if the row exists.
  ///
  /// Never throws to the UI caller: failures are swallowed after cleanup.
  Future<void> downloadAndAttach({
    required FoodItemRepository repository,
    required int itemId,
    required String imageUrl,
    void Function()? onAttached,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) return;

    String? tempPath;
    try {
      final existing = await repository.getById(itemId);
      if (existing == null) return;

      final response = await _http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      // Re-check after network I/O (item may have been deleted).
      if (await repository.getById(itemId) == null) return;

      final path = await pathForItem(itemId);
      tempPath = '$path.part';
      final part = File(tempPath);
      await part.writeAsBytes(response.bodyBytes, flush: true);

      if (await repository.getById(itemId) == null) {
        await deleteIfExists(tempPath);
        return;
      }

      final finalFile = File(path);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await part.rename(path);
      await repository.updateImagePath(itemId, path);
      onAttached?.call();
    } catch (_) {
      await deleteIfExists(tempPath);
      // Spec: failure must not block UI / corrupt inventory.
    }
  }

  void close() => _http.close();
}
