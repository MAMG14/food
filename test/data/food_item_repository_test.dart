import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
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
}
