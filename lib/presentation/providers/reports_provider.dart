import 'package:flutter/material.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../core/utils/money.dart';
import '../../providers/auth_provider.dart';

class ReportSummary {
  final int totalSalesCents;
  final int salesCount;
  final int cogsCents;
  final int expenseCents;
  final int grossProfitCents;
  final int netProfitCents;

  const ReportSummary({
    required this.totalSalesCents,
    required this.salesCount,
    required this.cogsCents,
    required this.expenseCents,
    required this.grossProfitCents,
    required this.netProfitCents,
  });

  ReportSummary copyWith({
    int? totalSalesCents,
    int? salesCount,
    int? cogsCents,
    int? expenseCents,
    int? grossProfitCents,
    int? netProfitCents,
  }) {
    return ReportSummary(
      totalSalesCents: totalSalesCents ?? this.totalSalesCents,
      salesCount: salesCount ?? this.salesCount,
      cogsCents: cogsCents ?? this.cogsCents,
      expenseCents: expenseCents ?? this.expenseCents,
      grossProfitCents: grossProfitCents ?? this.grossProfitCents,
      netProfitCents: netProfitCents ?? this.netProfitCents,
    );
  }
}

class ReportsProvider extends ChangeNotifier {
  final DashboardRepository _repo = DashboardRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ReportSummary _summary = const ReportSummary(
    totalSalesCents: 0,
    salesCount: 0,
    cogsCents: 0,
    expenseCents: 0,
    grossProfitCents: 0,
    netProfitCents: 0,
  );
  ReportSummary get summary => _summary;

  List<Map<String, dynamic>> _salesByProduct = [];
  List<Map<String, dynamic>> get salesByProduct => _salesByProduct;

  List<Map<String, dynamic>> _salesByPaymentMethod = [];
  List<Map<String, dynamic>> get salesByPaymentMethod => _salesByPaymentMethod;

  Future<void> loadReport(String filter, {DateTimeRange? customRange}) async {
    _isLoading = true;
    notifyListeners();

    final userId = AuthProvider.ofCurrentUserId();
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (filter) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case 'Yesterday':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case 'This Week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Week':
        final lastMonday = now.subtract(Duration(days: now.weekday + 6));
        start = DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
        end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = DateTime(lastMonth.year, lastMonth.month, 1);
        end = DateTime(lastMonth.year, lastMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case 'Custom':
        if (customRange == null) {
          start = now;
          end = now;
        } else {
          start = customRange.start;
          end = customRange.end;
        }
        break;
      default:
        start = now;
        end = now;
    }

    try {
      final reportData = await _repo.getReportData(userId, start: start, end: end);
      _summary = ReportSummary(
        totalSalesCents: reportData['totalSalesCents'] as int,
        salesCount: reportData['salesCount'] as int,
        cogsCents: reportData['cogsCents'] as int,
        expenseCents: reportData['expenseCents'] as int,
        grossProfitCents: reportData['grossProfitCents'] as int,
        netProfitCents: reportData['netProfitCents'] as int,
      );
      _salesByProduct = await _repo.getSalesByProduct(userId, start: start, end: end);
      _salesByPaymentMethod = await _repo.getSalesByPaymentMethod(userId, start: start, end: end);
    } catch (e) {
      // Handle errors appropriately in production.
    }

    _isLoading = false;
    notifyListeners();
  }
}
