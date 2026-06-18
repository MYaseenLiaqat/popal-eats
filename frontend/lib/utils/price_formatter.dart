/// Formats dish and order prices in Pakistani Rupees.
class PriceFormatter {
  PriceFormatter._();

  /// Examples: `PKR 650`, `PKR 75,000`, `PKR 1,250.50`
  static String format(num amount, {bool compact = false}) {
    if (amount.isNaN || amount.isInfinite) return 'PKR 0';
    final hasFraction = amount % 1 != 0;
    if (compact || !hasFraction) {
      return 'PKR ${_withCommas(amount.round())}';
    }
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    return 'PKR ${_withCommas(int.parse(parts[0]))}.${parts[1]}';
  }

  static String _withCommas(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Short prefix for input fields: `PKR `
  static const fieldPrefix = 'PKR ';
}
