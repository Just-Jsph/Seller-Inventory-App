/// Helper utilities for formatting data across the application
class Formatters {
  /// Format amount to currency string
  static String formatCurrency(double amount, {String symbol = r'$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
