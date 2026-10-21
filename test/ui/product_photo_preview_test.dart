import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/item/product_photo_preview.dart';

/// 1×1 PNG (opaque red).
final Uint8List _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
  0x0c, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xfe, 0xd4, 0xef, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

void main() {
  final image = MemoryImage(_tinyPng);
  final l10n = lookupAppLocalizations(const Locale('es'));

  Future<void> pumpPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
        home: Scaffold(
          body: ProductPhotoPreview(image: image),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('preview shows and is labeled for accessibility', (tester) async {
    await pumpPreview(tester);

    expect(find.byType(ProductPhotoPreview), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.productImageOpen), findsOneWidget);
  });

  testWidgets('tap opens fullscreen InteractiveViewer', (tester) async {
    await pumpPreview(tester);

    await tester.tap(find.byType(ProductPhotoPreview));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('close returns to preview', (tester) async {
    await pumpPreview(tester);

    await tester.tap(find.byType(ProductPhotoPreview));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byType(ProductPhotoPreview), findsOneWidget);
  });
}
