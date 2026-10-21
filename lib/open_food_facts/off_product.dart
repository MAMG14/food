/// Product payload from Open Food Facts (read-only API).
class OffProduct {
  const OffProduct({
    required this.code,
    this.productName,
    this.brands,
    this.quantity,
    this.categoriesTags = const [],
    this.imageFrontUrl,
  });

  final String code;
  final String? productName;
  final String? brands;
  final String? quantity;
  final List<String> categoriesTags;
  final String? imageFrontUrl;
}

/// Result of a barcode lookup.
sealed class OffLookupResult {
  const OffLookupResult();
}

class OffLookupMatch extends OffLookupResult {
  const OffLookupMatch(this.product);
  final OffProduct product;
}

class OffLookupNotFound extends OffLookupResult {
  const OffLookupNotFound();
}

class OffLookupFailure extends OffLookupResult {
  const OffLookupFailure(this.reason);
  final OffFailureReason reason;
}

enum OffFailureReason {
  network,
  timeout,
  server,
}
