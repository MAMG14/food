import 'dart:async';
import 'dart:convert';

import 'package:food/domain/open_food_facts_mapping.dart';
import 'package:food/open_food_facts/off_product.dart';
import 'package:http/http.dart' as http;

/// Read-only Open Food Facts client (product by barcode).
class OffApiClient {
  OffApiClient({
    http.Client? httpClient,
    this.baseUrl = 'https://world.openfoodfacts.org',
    this.timeout = const Duration(seconds: 12),
    this.userAgent =
        'AlacenaBunker/1.0 (Flutter; https://github.com/MAMG14/food)',
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;
  final String userAgent;

  static const _fields =
      'product_name,brands,quantity,categories_tags,image_front_url,code';

  /// Looks up [barcode]; never throws — returns [OffLookupResult].
  Future<OffLookupResult> fetchByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return const OffLookupNotFound();

    final uri = Uri.parse(
      '$baseUrl/api/v2/product/$code.json',
    ).replace(queryParameters: {'fields': _fields});

    try {
      final response = await _http
          .get(
            uri,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 404) {
        return const OffLookupNotFound();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const OffLookupFailure(OffFailureReason.server);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const OffLookupFailure(OffFailureReason.server);
      }

      final status = decoded['status'];
      if (status != 1) {
        return const OffLookupNotFound();
      }

      final productMap = decoded['product'];
      if (productMap is! Map<String, dynamic>) {
        return const OffLookupNotFound();
      }

      final product = _parseProduct(productMap, code);
      final draft = offProductToDraft(
        OffProductInput(
          productName: product.productName,
          brands: product.brands,
          quantity: product.quantity,
          categoriesTags: product.categoriesTags,
          imageUrl: product.imageFrontUrl,
          barcode: product.code,
        ),
      );
      if (draft == null) {
        return const OffLookupNotFound();
      }
      return OffLookupMatch(product);
    } on TimeoutException {
      return const OffLookupFailure(OffFailureReason.timeout);
    } on http.ClientException {
      return const OffLookupFailure(OffFailureReason.network);
    } on FormatException {
      return const OffLookupFailure(OffFailureReason.server);
    } catch (_) {
      return const OffLookupFailure(OffFailureReason.network);
    }
  }

  void close() => _http.close();

  OffProduct _parseProduct(Map<String, dynamic> map, String fallbackCode) {
    final tags = map['categories_tags'];
    return OffProduct(
      code: (map['code'] as String?)?.trim().isNotEmpty == true
          ? map['code'] as String
          : fallbackCode,
      productName: map['product_name'] as String?,
      brands: map['brands'] as String?,
      quantity: map['quantity'] as String?,
      categoriesTags: tags is List
          ? tags.whereType<String>().toList()
          : const [],
      imageFrontUrl: map['image_front_url'] as String?,
    );
  }
}
