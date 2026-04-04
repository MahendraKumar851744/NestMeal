/// Safely converts a dynamic value (String, int, double, null) to double.
/// DRF DecimalFields are often serialized as strings like "12.50".
double toSafeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String currencySymbol(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'AUD': return '\$';
    case 'INR': return '₹';
    case 'USD': return '\$';
    case 'EUR': return '€';
    default: return currencyCode;
  }
}
