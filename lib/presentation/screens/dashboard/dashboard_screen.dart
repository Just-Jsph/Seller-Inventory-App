import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/sales_chart_card.dart';
import '../sales/add_sale_screen.dart';
import '../inventory/add_product_screen.dart';
import '../inventory/restock_screen.dart';
import '../debts/add_debt_screen.dart';
import '../debts/record_payment_screen.dart';

/// Comprehensive Dashboard screen for Small Business Manager.
class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex, {int subTabIndex})? onNavigateToTab;

  const DashboardScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  Future<void> _refreshDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
      final invProvider = Provider.of<InventoryProvider>(context, listen: false);
      await Future.wait([
        dashProvider.loadDashboardData(userId),
        invProvider.loadData(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashProvider = Provider.of<DashboardProvider>(context);
    final user = authProvider.currentUser;
    final summary = dashProvider.summary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              final alertMsg = summary.lowStockCount > 0
                  ? '${summary.lowStockCount} item(s) are low in stock!'
                  : 'All business metrics are up to date.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(alertMsg),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: dashProvider.isLoading && summary == DashboardSummaryData.empty()
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Banner
                _buildWelcomeHeader(context, user?.name ?? 'Seller', isDark),
                const SizedBox(height: 20),

                // 2. Quick Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Shortcuts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scrollable Quick Action Chips (Add Sale, Add Product, Restock, Add Debt, Debt Payment)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 1. Add Sale
                      _buildQuickActionButton(
                        context: context,
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Add Sale',
                        color: AppColors.primary,
                        onTap: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddSaleScreen()),
                          );
                          if (res == true) _refreshDashboard();
                        },
                      ),
                      const SizedBox(width: 10),

                      // 2. Add Product
                      _buildQuickActionButton(
                        context: context,
                        icon: Icons.add_box_rounded,
                        label: 'Add Product',
                        color: AppColors.secondary,
                        onTap: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddProductScreen()),
                          );
                          if (res == true) _refreshDashboard();
                        },
                      ),
                      const SizedBox(width: 10),

                      // 3. Restock
                      _buildQuickActionButton(
                        context: context,
                        icon: Icons.published_with_changes_rounded,
                        label: 'Restock',
                        color: Colors.teal.shade700,
                        onTap: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RestockScreen()),
                          );
                          if (res == true) _refreshDashboard();
                        },
                      ),
                      const SizedBox(width: 10),

                      // 4. Add Debt
                      _buildQuickActionButton(
                        context: context,
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Add Debt',
                        color: AppColors.warning,
                        onTap: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                          );
                          if (res == true) _refreshDashboard();
                        },
                      ),
                      const SizedBox(width: 10),

                      // 5. Debt Payment
                      _buildQuickActionButton(
                        context: context,
                        icon: Icons.payments_rounded,
                        label: 'Debt Payment',
                        color: Colors.deepOrange,
                        onTap: () async {
                          final res = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
                          );
                          if (res == true) _refreshDashboard();
                        },
                      ),
    const SizedBox(width: 10),
    // 6. Reports
    _buildQuickActionButton(
      context: context,
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      color: AppColors.success,
      onTap: () async {
        final res = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        if (res == true) _refreshDashboard();
      },
    ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Key Performance Indicators Section (7 Metrics)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overview & Performance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Real-time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid of 7 KPI Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    final crossAxisCount = isTablet ? 4 : 2;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isTablet ? 1.4 : 1.05,
                      children: [
                        // 1. Today's Sales
                        KpiCard(
                          title: "Today's Sales",
                          value: Money.format(summary.todaySalesCents),
                          subtitle: '${summary.todaySalesCount} sale(s) today',
                          icon: Icons.point_of_sale_rounded,
                          color: AppColors.primary,
                          onTap: () => widget.onNavigateToTab?.call(1, subTabIndex: 0),
                        ),

                        // 2. Today's COGS (Cost of Goods Sold)
                        KpiCard(
                          title: "Today's COGS",
                          value: Money.format(summary.todayCogsCents),
                          subtitle: 'Cost of goods sold',
                          icon: Icons.production_quantity_limits_rounded,
                          color: AppColors.error,
                          onTap: () => widget.onNavigateToTab?.call(4, subTabIndex: 1),
                        ),

                        // 3. Today's Expenses
                        KpiCard(
                          title: "Today's Expenses",
                          value: Money.format(summary.todayExpenseCents),
                          subtitle: 'Operational expenses',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.orangeAccent,
                          onTap: () => widget.onNavigateToTab?.call(4, subTabIndex: 2),
                        ),

                        // 4. Today's Gross Profit
                        KpiCard(
                          title: "Today's Gross Profit",
                          value: Money.format(summary.todayGrossProfitCents),
                          subtitle: summary.todayGrossProfitCents >= 0 ? 'Revenue - COGS' : 'Loss',
                          icon: Icons.trending_up_rounded,
                          color: summary.todayGrossProfitCents >= 0 ? AppColors.success : AppColors.error,
                          onTap: () => widget.onNavigateToTab?.call(4, subTabIndex: 3),
                        ),

                        // 5. Today's Net Profit
                        KpiCard(
                          title: "Today's Net Profit",
                          value: Money.format(summary.todayNetProfitCents),
                          subtitle: summary.todayNetProfitCents >= 0 ? 'Profit after expenses' : 'Net loss',
                          icon: Icons.account_balance_wallet_rounded,
                          color: summary.todayNetProfitCents >= 0 ? AppColors.success : AppColors.error,
                          onTap: () => widget.onNavigateToTab?.call(4, subTabIndex: 4),
                        ),

                        // 4. Current Inventory
                        KpiCard(
                          title: 'Current Inventory',
                          value: '${summary.totalInventoryItems} Items',
                          subtitle: 'Valued at ${Money.format(summary.totalInventoryValueCents)}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.secondary,
                          onTap: () => widget.onNavigateToTab?.call(2, subTabIndex: 0),
                        ),

                        // 5. Total Debt
                        KpiCard(
                          title: 'Total Debt',
                          value: Money.format(summary.totalDebtCents),
                          subtitle: 'Outstanding balance',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.warning,
                          onTap: () => widget.onNavigateToTab?.call(3, subTabIndex: 0),
                        ),

                        // 6. Number of Debtors
                        KpiCard(
                          title: 'Number of Debtors',
                          value: '${summary.numberOfDebtors} Debtors',
                          subtitle: summary.numberOfDebtors > 0 ? 'Active debtor accounts' : 'No open debts',
                          icon: Icons.people_alt_rounded,
                          color: Colors.deepOrange,
                          onTap: () => widget.onNavigateToTab?.call(3, subTabIndex: 0),
                        ),

                        // 7. Low Stock
                        KpiCard(
                          title: 'Low Stock',
                          value: '${summary.lowStockCount} Items',
                          subtitle: summary.lowStockCount > 0 ? 'Needs replenishment' : 'Stock levels healthy',
                          icon: Icons.warning_amber_rounded,
                          color: summary.lowStockCount > 0 ? Colors.amber.shade800 : AppColors.success,
                          onTap: () => widget.onNavigateToTab?.call(2, subTabIndex: 0),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 4. Sales Revenue Trend Chart
                SalesChartCard(
                  data: summary.dailySalesChartData,
                  selectedDays: dashProvider.selectedChartDays,
                  isLoading: dashProvider.isLoading,
                  onDaysChanged: (days) {
                    if (user?.id != null) {
                      dashProvider.setChartDays(user!.id!, days);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 5. Low Stock Quick Alert Banner (If items need restock)
                if (summary.lowStockCount > 0)
                  Card(
                    elevation: 0,
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${summary.lowStockCount} Product(s) Low in Stock',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Replenish inventory to avoid running out of stock.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final res = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RestockScreen()),
                              );
                              if (res == true) _refreshDashboard();
                            },
                            child: const Text('Restock Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String userName, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.primary, const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Small Business Manager Dashboard',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
