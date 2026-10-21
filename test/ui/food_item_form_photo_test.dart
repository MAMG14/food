import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/product_image_store.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/item/food_item_form_page.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late FoodDatabase db;
  late FoodItemRepository repo;
  late ProductImageStore store;
  final l10n = lookupAppLocalizations(const Locale('es'));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_form_photo_');
    db = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'test.db'),
    );
    repo = FoodItemRepository(db);
    store = ProductImageStore(
      documentsDirectory: () => Directory(p.join(tempDir.path, 'imgs')),
    );
  });

  tearDown(() async {
    store.close();
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  testWidgets('manual form shows add-photo action', (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FoodItemFormPage(
          repository: repo,
          imageStore: store,
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.productImageAdd), findsOneWidget);
    expect(find.text(l10n.productImageCamera), findsNothing);

    await tester.tap(find.text(l10n.productImageAdd));
    await tester.pumpAndSettle();
    expect(find.text(l10n.productImageCamera), findsOneWidget);
    expect(find.text(l10n.productImageGallery), findsOneWidget);
  });

  test('update without changing imagePath keeps photo (RF-19)', () async {
    final imageFile = File(p.join(tempDir.path, 'existing.png'));
    await imageFile.writeAsBytes([1, 2, 3]);

    final saved = await repo.insert(
      FoodItem(
        name: 'Leche',
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-12-01',
        quantity: 1,
        unit: Unit.pz,
        category: Category.dairy,
        location: StorageLocation.fridge,
        imagePath: imageFile.path,
        barcode: '123',
      ),
    );

    // Same contract as the form when the user does not touch the photo.
    await repo.update(
      saved.copyWith(name: 'Leche entera', imagePath: saved.imagePath),
    );

    final found = await repo.getById(saved.id!);
    expect(found!.imagePath, imageFile.path);
    expect(found.barcode, '123');
    expect(found.name, 'Leche entera');
  });

  test('attachFromFile after insert mimics form save with gallery pick', () async {
    final picked = File(p.join(tempDir.path, 'picked.png'));
    await picked.writeAsBytes([4, 5, 6]);

    final saved = await repo.insert(
      const FoodItem(
        name: 'Yogur',
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-12-01',
        quantity: 1,
        unit: Unit.pz,
        category: Category.dairy,
        location: StorageLocation.fridge,
      ),
    );

    final path = await store.attachFromFile(
      repository: repo,
      itemId: saved.id!,
      sourcePath: picked.path,
    );
    expect(path, isNotNull);
    final found = await repo.getById(saved.id!);
    expect(found!.imagePath, path);
  });
}
