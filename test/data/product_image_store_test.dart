import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late FoodDatabase foodDb;
  late FoodItemRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_img_');
    foodDb = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'test.db'),
    );
    repo = FoodItemRepository(foodDb);
  });

  tearDown(() async {
    await foodDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  FoodItem sample() => const FoodItem(
        name: 'Item',
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-12-01',
        quantity: 1,
        unit: Unit.pz,
        category: Category.other,
        location: StorageLocation.other,
      );

  test('downloadAndAttach writes file and updates imagePath', () async {
    final imageDir = Directory(p.join(tempDir.path, 'imgs'));
    final store = ProductImageStore(
      documentsDirectory: () => imageDir,
      httpClient: MockClient(
        (_) async => http.Response.bytes([1, 2, 3, 4], 200),
      ),
    );
    final saved = await repo.insert(sample());
    await store.downloadAndAttach(
      repository: repo,
      itemId: saved.id!,
      imageUrl: 'https://example.com/p.jpg',
    );
    final found = await repo.getById(saved.id!);
    expect(found!.imagePath, isNotNull);
    expect(File(found.imagePath!).existsSync(), isTrue);
    store.close();
  });

  test('downloadAndAttach no-ops if item deleted during download', () async {
    final imageDir = Directory(p.join(tempDir.path, 'imgs2'));
    final store = ProductImageStore(
      documentsDirectory: () => imageDir,
      httpClient: MockClient((_) async {
        // Delete while "downloading".
        final all = await repo.getAll();
        await repo.delete(all.first.id!);
        return http.Response.bytes([9, 9], 200);
      }),
    );
    final saved = await repo.insert(sample());
    await store.downloadAndAttach(
      repository: repo,
      itemId: saved.id!,
      imageUrl: 'https://example.com/p.jpg',
    );
    expect(await repo.getById(saved.id!), isNull);
    final leftovers = imageDir.existsSync()
        ? imageDir.listSync().whereType<File>().toList()
        : <File>[];
    expect(leftovers, isEmpty);
    store.close();
  });

  test('HTTP failure does not throw or set path', () async {
    final imageDir = Directory(p.join(tempDir.path, 'imgs3'));
    final store = ProductImageStore(
      documentsDirectory: () => imageDir,
      httpClient: MockClient((_) async => http.Response('no', 404)),
    );
    final saved = await repo.insert(sample());
    await store.downloadAndAttach(
      repository: repo,
      itemId: saved.id!,
      imageUrl: 'https://example.com/missing.jpg',
    );
    final found = await repo.getById(saved.id!);
    expect(found!.imagePath, isNull);
    store.close();
  });
}
