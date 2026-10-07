import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:sqflite/sqflite.dart';

import 'food_database.dart';

/// CRUD for [FoodItem] rows in SQLite.
class FoodItemRepository {
  FoodItemRepository(this._foodDatabase);

  final FoodDatabase _foodDatabase;

  Future<Database> get _db => _foodDatabase.database;

  Future<List<FoodItem>> getAll() async {
    final rows = await (await _db).query(
      'food_items',
      orderBy: 'id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<FoodItem?> getById(int id) async {
    final rows = await (await _db).query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<FoodItem> insert(FoodItem item) async {
    final now = DateTime.now().toIso8601String();
    final id = await (await _db).insert('food_items', {
      ..._toRow(item),
      'created_at': now,
      'updated_at': now,
    });
    return item.copyWith(id: id);
  }

  Future<FoodItem> update(FoodItem item) async {
    final id = item.id;
    if (id == null) {
      throw ArgumentError('Cannot update FoodItem without id');
    }
    final now = DateTime.now().toIso8601String();
    await (await _db).update(
      'food_items',
      {
        ..._toRow(item),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return item;
  }

  Future<void> delete(int id) async {
    await (await _db).delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(FoodItem item) {
    return {
      'name': item.name,
      'expiry_precision': item.expiryPrecision.name,
      'expiry_value': item.expiryValue,
      'quantity': item.quantity,
      'unit': item.unit.name,
      'category': item.category.name,
      'notes': item.notes,
      'location': item.location.name,
    };
  }

  FoodItem _fromRow(Map<String, Object?> row) {
    return FoodItem(
      id: row['id'] as int,
      name: row['name'] as String,
      expiryPrecision: ExpiryPrecision.values.byName(
        row['expiry_precision'] as String,
      ),
      expiryValue: row['expiry_value'] as String,
      quantity: (row['quantity'] as num).toDouble(),
      unit: Unit.values.byName(row['unit'] as String),
      category: Category.values.byName(row['category'] as String),
      notes: row['notes'] as String?,
      location: StorageLocation.values.byName(row['location'] as String),
    );
  }
}
