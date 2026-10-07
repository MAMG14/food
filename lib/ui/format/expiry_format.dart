import 'package:flutter/material.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:intl/intl.dart';

/// Formats expiry for list/detail according to precision (RF-15).
String formatExpiry(FoodItem item, Locale locale) {
  final languageTag = locale.toLanguageTag();
  if (item.expiryPrecision == ExpiryPrecision.month) {
    final parts = item.expiryValue.split('-');
    if (parts.length != 2) return item.expiryValue;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return item.expiryValue;
    final date = DateTime(year, month);
    return DateFormat.yMMMM(languageTag).format(date);
  }

  final parts = item.expiryValue.split('-');
  if (parts.length != 3) return item.expiryValue;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return item.expiryValue;
  final date = DateTime(year, month, day);
  return DateFormat.yMMMMd(languageTag).format(date);
}

String formatYearMonth(DateTime date, Locale locale) {
  return DateFormat.yMMMM(locale.toLanguageTag()).format(
    DateTime(date.year, date.month),
  );
}
