import 'dart:io';

import 'package:food/data/food_item_repository.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local product image files under the app documents directory.
///
/// Contract (spec 005): insert item with `imagePath == null`, then
/// [downloadAndAttach] — update path only if the item still exists.
class ProductImageStore {
  ProductImageStore({
    this.documentsDirectory,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Override for tests (temp directory).
  final Directory? Function()? documentsDirectory;

  final http.Client _http;

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

  /// Downloads [imageUrl] and sets `image_path` on [itemId] if the row exists.
  ///
  /// Never throws to the UI caller: failures are swallowed after cleanup.
  Future<void> downloadAndAttach({
    required FoodItemRepository repository,
    required int itemId,
    required String imageUrl,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) return;

    String? tempPath;
    try {
      final existing = await repository.getById(itemId);
      if (existing == null) return;

      final response = await _http.get(Uri.parse(url));
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
    } catch (_) {
      await deleteIfExists(tempPath);
      // Spec: failure must not block UI / corrupt inventory.
    }
  }

  void close() => _http.close();
}
