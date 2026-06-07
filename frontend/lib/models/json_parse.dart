/// Shared JSON parsing helpers for API models.
library;

int parseInt(dynamic value, {required String field}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Expected int for $field, got ${value.runtimeType}');
}

double parseDouble(dynamic value, {required String field}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected number for $field, got ${value.runtimeType}');
}

double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

DateTime? parseDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

bool parseBool(dynamic value, {bool fallback = true}) {
  if (value is bool) return value;
  return fallback;
}
