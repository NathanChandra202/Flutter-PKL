import 'dart:convert';

import 'package:intl/intl.dart';

/// Parse [additional_images] from comma-separated string (or legacy JSON array).
List<String> parseAdditionalImages(dynamic raw) {
  if (raw == null) return [];
  final str = raw.toString().trim();
  if (str.isEmpty) return [];

  try {
    final decoded = json.decode(str);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
  } catch (_) {}

  return str
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Resolve relative upload paths (e.g. `/uploads/rooms/...`) to absolute URL.
String resolveMediaUrl(String url, String apiBaseUrl) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/$url';
}

String formatRupiah(dynamic value) {
  if (value == null) return 'Rp 0';
  
  num numericValue;
  if (value is String) {
    numericValue = num.tryParse(value) ?? 0;
  } else if (value is num) {
    numericValue = value;
  } else {
    return 'Rp 0';
  }
  
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  return formatter.format(numericValue);
}
