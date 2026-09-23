import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/kpi_card.dart';
import '../sales/add_sale_screen.dart';
import '../inventory/add_product_screen.dart';
import '../inventory/restock_screen.dart';
import '../debts/add_debt_screen.dart';

/// The central Dashboard screen for Small Business Manager.
/// Provides quick access to:
/// - Today's Sales
/// - Add Sale
/// - Current Inventory
/// - Current Profit
/// - Current Costs
/// - Outstanding Debt
/// - Debtors
/// - Low Stock
class DashboardScreen extends StatelessWidget {
  final Function(int tabIndex, {int subTabIndex})? onNavigateToTab;

  const DashboardScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);
    final user = authProvider.currentUser;
    final invSummary = invProvider.summary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new alerts. Business health is optimal.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user?.id != null) {
              await invProvider.loadData(user!.id!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome / Profile Banner
                _buildWelcomeHeader(context, user?.name ?? 'Seller', isDark),
                const SizedBox(height: 18),

                // Section 1: Key Performance Indicators (Quick Access)
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
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2x2 or responsive Grid of KPI Cards
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
                          value: '₱0.00',
                          subtitle: '0 transactions today',
                          icon: Icons.point_of_sale_rounded,
                          color: AppColors.primary,
                          onTap: () => onNavigateToTab?.call(1, subTabIndex: 0),
                        ),

                        // 2. Current Profit
                        KpiCard(
                          title: 'Current Profit',
                          value: '₱0.00',
                          subtitle: 'Gross profit today',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.success,
                          onTap: () => onNavigateToTab?.call(4, subTabIndex: 2), // Reports -> Profit
                        ),

                        // 3. Current Costs
                        KpiCard(
                          title: 'Current Costs',
                          value: '₱0.00',
                          subtitle: 'Expenses & COGS',
                          icon: Icons.account_balance_rounded,
                          color: AppColors.error,
                          onTap: () => onNavigateToTab?.call(4, subTabIndex: 1), // Reports -> Cost
                        ),

                        // 4. Current Inventory
                        KpiCard(
                          title: 'Current Inventory',
                          value: '${invSummary.totalProducts} Items',
                          subtitle: 'Cost: ₱${(invSummary.totalCostCents / 100.0).toStringAsFixed(2)}',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.secondary,
                          onTap: () => onNavigateToTab?.call(2, subTabIndex: 0), // Inventory -> Stock
                        ),

                        // 5. Outstanding Debt
                        KpiCard(
                          title: 'Outstanding Debt',
                          value: '₱0.00',
                          subtitle: 'Total receivables',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.warning,
                          onTap: () => onNavigateToTab?.call(3, subTabIndex: 0), // Debts -> Debtors
                        ),

                        // 6. Debtors
                        KpiCard(
                          title: 'Active Debtors',
                          value: '0 Customers',
                          subtitle: '0 overdue accounts',
                          icon: Icons.people_alt_rounded,
                          color: Colors.deepOrange,
                          onTap: () => onNavigateToTab?.call(3, subTabIndex: 0), // Debts -> Debtors
                        ),

                        // 7. Low Stock
                        KpiCard(
                          title: 'Low Stock Alert',
                          value: '${invSummary.lowStockCount + invSummary.outOfStockCount} Items',
                          subtitle: invSummary.lowStockCount + invSummary.outOfStockCount > 0
                              ? 'Needs replenishment'
                              : 'Stock level healthy',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                          onTap: () => onNavigateToTab?.call(2, subTabIndex: 0), // Inventory -> Stock
                        ),

                        // 8. Sales History
                        KpiCard(
                          title: 'Sales History',
                          value: 'All Records',
                          subtitle: 'Tap to view log',
                          icon: Icons.history_rounded,
                          color: Colors.indigo,
                          onTap: () => onNavigateToTab?.call(1, subTabIndex: 1), // Sales -> History
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Section 2: Quick Actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Action Buttons Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Quick Action: Add Sale
                      _buildQuickActionChip(
                        context: context,
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Add Sale',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddSaleScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Quick Action: Add Product
                      _buildQuickActionChip(
                        context: context,
                        icon: Icons.add_box_rounded,
                        label: 'Add Product',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddProductScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Quick Action: Restock
                      _buildQuickActionChip(
                        context: context,
                        icon: Icons.published_with_changes_rounded,
                        label: 'Restock',
                        color: Colors.teal.shade700,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RestockScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Quick Action: Add Debt
                      _buildQuickActionChip(
                        context: context,
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Add Debt',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Quick Action: View Reports
                      _buildQuickActionChip(
                        context: context,
                        icon: Icons.analytics_outlined,
                        label: 'Reports',
                        color: AppColors.info,
                        onTap: () => onNavigateToTab?.call(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Business Readiness & Status Notice
                Card(
                  elevation: 0,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.primary.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Navigation Structure Ready',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All main modules (Sales, Inventory, Debts, Reports, Settings) are wired up with Material 3 navigation and ready for database calculations.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String userName, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
                  'Hello, $userName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Store Management Dashboard',
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
                Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Online',
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

  Widget _buildQuickActionChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
