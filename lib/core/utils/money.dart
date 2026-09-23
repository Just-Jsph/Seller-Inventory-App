/// Precise monetary calculations using integer cents to prevent floating-point rounding errors.
class Money {
  /// Converts a decimal dollar amount to integer cents (e.g., 12.50 -> 1250)
  static int fromDouble(double amount) {
    return (amount * 100).round();
  }

  /// Converts integer cents to a decimal double (e.g., 1250 -> 12.50)
  static double toDouble(int cents) {
    return cents / 100.0;
  }

  /// Formats integer cents to a formatted currency string (e.g., 1250 -> "$12.50")
  static String format(int cents, {String symbol = r'$'}) {
    final double amount = toDouble(cents);
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
