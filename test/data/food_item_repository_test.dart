import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
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
    tempDir = await Directory.systemTemp.createTemp('food_db_test_');
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

  FoodItem sample({String name = 'Leche'}) {
    return FoodItem(
      name: name,
      expiryPrecision: ExpiryPrecision.day,
      expiryValue: '2026-12-01',
      quantity: 1,
      unit: Unit.pz,
      category: Category.dairy,
      location: StorageLocation.fridge,
    );
  }

  test('insert and getAll', () async {
    final saved = await repo.insert(sample());
    expect(saved.id, isNotNull);

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Leche');
    expect(all.first.expiryPrecision, ExpiryPrecision.day);
  });

  test('update', () async {
    final saved = await repo.insert(sample());
    await repo.update(
      saved.copyWith(
        name: 'Yogur',
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '2026-11',
      ),
    );
    final found = await repo.getById(saved.id!);
    expect(found!.name, 'Yogur');
    expect(found.expiryValue, '2026-11');
  });

  test('delete', () async {
    final saved = await repo.insert(sample());
    await repo.delete(saved.id!);
    expect(await repo.getAll(), isEmpty);
  });

  test('insert and read barcode and imagePath', () async {
    final saved = await repo.insert(
      sample().copyWith(barcode: '3017624010701', imagePath: '/tmp/x.jpg'),
    );
    final found = await repo.getById(saved.id!);
    expect(found!.barcode, '3017624010701');
    expect(found.imagePath, '/tmp/x.jpg');
  });

  test('updateImagePath', () async {
    final saved = await repo.insert(sample());
    await repo.updateImagePath(saved.id!, '/imgs/item.jpg');
    final found = await repo.getById(saved.id!);
    expect(found!.imagePath, '/imgs/item.jpg');
  });

  test('delete removes local image file', () async {
    final imageDir = Directory(p.join(tempDir.path, 'images'));
    await imageDir.create();
    final imageFile = File(p.join(imageDir.path, 'item.jpg'));
    await imageFile.writeAsString('fake');
    final store = ProductImageStore(documentsDirectory: () => imageDir);
    final repoWithStore = FoodItemRepository(foodDb, imageStore: store);

    final saved = await repoWithStore.insert(
      sample().copyWith(imagePath: imageFile.path),
    );
    await repoWithStore.delete(saved.id!);
    expect(imageFile.existsSync(), isFalse);
  });

  test('migration v2 to v3 keeps existing rows', () async {
    final path = p.join(tempDir.path, 'migrate.db');
    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE food_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  expiry_precision TEXT NOT NULL,
  expiry_value TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  category TEXT NOT NULL,
  notes TEXT,
  location TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
          await db.execute('''
CREATE TABLE reminder_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  enabled INTEGER NOT NULL,
  general_lead_days INTEGER NOT NULL,
  notify_hour INTEGER NOT NULL,
  notify_minute INTEGER NOT NULL,
  permission_asked INTEGER NOT NULL
)
''');
          await db.execute('''
CREATE TABLE category_reminder_rules (
  category TEXT PRIMARY KEY,
  mode TEXT NOT NULL,
  lead_days INTEGER
)
''');
          await db.execute('''
CREATE TABLE reminder_log (
  item_id INTEGER PRIMARY KEY,
  fire_at TEXT NOT NULL,
  expiry_key TEXT NOT NULL
)
''');
        },
      ),
    );
    final now = DateTime.now().toIso8601String();
    await v2.insert('food_items', {
      'name': 'Legacy',
      'expiry_precision': 'day',
      'expiry_value': '2026-12-01',
      'quantity': 1,
      'unit': 'pz',
      'category': 'other',
      'notes': null,
      'location': 'other',
      'created_at': now,
      'updated_at': now,
    });
    await v2.close();

    final migrated = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    final migratedRepo = FoodItemRepository(migrated);
    final all = await migratedRepo.getAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Legacy');
    expect(all.first.barcode, isNull);
    expect(all.first.imagePath, isNull);
    await migrated.close();
  });
}
