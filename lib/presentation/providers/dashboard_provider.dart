import 'package:flutter/foundation.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/services/inventory_service.dart';

class DashboardSummaryData {
  final int todaySalesCents;
  final int todaySalesCount;
  final int todayCostCents;
  final int todayProfitCents;
  final int totalInventoryItems;
  final int totalInventoryValueCents;
  final int totalDebtCents;
  final int numberOfDebtors;
  final int lowStockCount;
  final List<DailySalesData> dailySalesChartData;

  DashboardSummaryData({
    required this.todaySalesCents,
    required this.todaySalesCount,
    required this.todayCostCents,
    required this.todayProfitCents,
    required this.totalInventoryItems,
    required this.totalInventoryValueCents,
    required this.totalDebtCents,
    required this.numberOfDebtors,
    required this.lowStockCount,
    required this.dailySalesChartData,
  });

  factory DashboardSummaryData.empty() => DashboardSummaryData(
        todaySalesCents: 0,
        todaySalesCount: 0,
        todayCostCents: 0,
        todayProfitCents: 0,
        totalInventoryItems: 0,
        totalInventoryValueCents: 0,
        totalDebtCents: 0,
        numberOfDebtors: 0,
        lowStockCount: 0,
        dailySalesChartData: [],
      );
}

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepo;
  final InventoryService _inventoryService;

  DashboardSummaryData _summary = DashboardSummaryData.empty();
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedChartDays = 7;

  DashboardProvider({
    DashboardRepository? dashboardRepo,
    InventoryService? inventoryService,
  })  : _dashboardRepo = dashboardRepo ?? DashboardRepository(),
        _inventoryService = inventoryService ?? InventoryService();

  DashboardSummaryData get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedChartDays => _selectedChartDays;

  /// Load all dashboard statistics from database
  Future<void> loadDashboardData(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dashboardRepo.getTodaySales(userId),
        _dashboardRepo.getTodayCost(userId),
        _dashboardRepo.getTotalDebtCents(userId),
        _dashboardRepo.getNumberOfDebtors(userId),
        _inventoryService.getInventorySummary(userId),
        _dashboardRepo.getSalesChartData(userId, days: _selectedChartDays),
      ]);

      final todaySalesMap = results[0] as Map<String, dynamic>;
      final todayCostMap = results[1] as Map<String, dynamic>;
      final totalDebtCents = results[2] as int;
      final numberOfDebtors = results[3] as int;
      final invSummary = results[4] as InventorySummary;
      final chartData = results[5] as List<DailySalesData>;

      final todaySalesCents = todaySalesMap['totalSalesCents'] as int;
      final todaySalesCount = todaySalesMap['salesCount'] as int;
      final todayCostCents = todayCostMap['totalCostCents'] as int;
      final todayProfitCents = todaySalesCents - todayCostCents;

      _summary = DashboardSummaryData(
        todaySalesCents: todaySalesCents,
        todaySalesCount: todaySalesCount,
        todayCostCents: todayCostCents,
        todayProfitCents: todayProfitCents,
        totalInventoryItems: invSummary.totalProducts,
        totalInventoryValueCents: invSummary.totalCostCents,
        totalDebtCents: totalDebtCents,
        numberOfDebtors: numberOfDebtors,
        lowStockCount: invSummary.lowStockCount + invSummary.outOfStockCount,
        dailySalesChartData: chartData,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change chart period (7, 14, 30 days) and reload chart data
  Future<void> setChartDays(int userId, int days) async {
    _selectedChartDays = days;
    notifyListeners();
    try {
      final chartData = await _dashboardRepo.getSalesChartData(userId, days: days);
      _summary = DashboardSummaryData(
        todaySalesCents: _summary.todaySalesCents,
        todaySalesCount: _summary.todaySalesCount,
        todayCostCents: _summary.todayCostCents,
        todayProfitCents: _summary.todayProfitCents,
        totalInventoryItems: _summary.totalInventoryItems,
        totalInventoryValueCents: _summary.totalInventoryValueCents,
        totalDebtCents: _summary.totalDebtCents,
        numberOfDebtors: _summary.numberOfDebtors,
        lowStockCount: _summary.lowStockCount,
        dailySalesChartData: chartData,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
