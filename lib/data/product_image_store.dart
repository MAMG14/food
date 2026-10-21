import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local product image files under the app documents directory.
///
/// Full download-and-attach lives in T4; this owns paths and deletion (T2).
class ProductImageStore {
  ProductImageStore({this.documentsDirectory});

  /// Override for tests (temp directory).
  final Directory? Function()? documentsDirectory;

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
}
