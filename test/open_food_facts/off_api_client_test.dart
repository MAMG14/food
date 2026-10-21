import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/open_food_facts/off_api_client.dart';
import 'package:food/open_food_facts/off_product.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('match returns product when status is 1 and name usable', () async {
    final client = OffApiClient(
      httpClient: MockClient((request) async {
        expect(request.headers['User-Agent'], contains('AlacenaBunker'));
        expect(request.url.path, contains('/api/v2/product/123.json'));
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'code': '123',
              'product_name': 'Noodles',
              'brands': 'Thai',
              'quantity': '155 g',
              'categories_tags': ['en:pastas'],
              'image_front_url': 'https://example.com/n.jpg',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await client.fetchByBarcode('123');
    expect(result, isA<OffLookupMatch>());
    final product = (result as OffLookupMatch).product;
    expect(product.productName, 'Noodles');
    expect(product.brands, 'Thai');
    client.close();
  });

  test('status 0 is not found', () async {
    final client = OffApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'status': 0, 'status_verbose': 'product not found'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    expect(await client.fetchByBarcode('999'), isA<OffLookupNotFound>());
    client.close();
  });

  test('empty product name is not found', () async {
    final client = OffApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 1,
            'product': {'code': '1', 'product_name': '  '},
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    expect(await client.fetchByBarcode('1'), isA<OffLookupNotFound>());
    client.close();
  });

  test('HTTP 500 is server failure', () async {
    final client = OffApiClient(
      httpClient: MockClient(
        (_) async => http.Response('nope', 500),
      ),
    );
    final result = await client.fetchByBarcode('1');
    expect(result, isA<OffLookupFailure>());
    expect(
      (result as OffLookupFailure).reason,
      OffFailureReason.server,
    );
    client.close();
  });

  test('timeout is timeout failure', () async {
    final client = OffApiClient(
      timeout: const Duration(milliseconds: 20),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      }),
    );
    final result = await client.fetchByBarcode('1');
    expect(result, isA<OffLookupFailure>());
    expect(
      (result as OffLookupFailure).reason,
      OffFailureReason.timeout,
    );
    client.close();
  });

  test('network error is network failure', () async {
    final client = OffApiClient(
      httpClient: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    final result = await client.fetchByBarcode('1');
    expect(result, isA<OffLookupFailure>());
    expect(
      (result as OffLookupFailure).reason,
      OffFailureReason.network,
    );
    client.close();
  });
}
