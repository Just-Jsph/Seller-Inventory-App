import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'sales_report_view.dart';
import 'cost_report_view.dart';
import 'profit_report_view.dart';
import 'sales_comparison_view.dart';

/// Main Reports hub containing Sales Report, Cost Report, Profit Report, and Sales Comparison tabs.
class ReportsScreen extends StatefulWidget {
  final int initialTabIndex;

  const ReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.tertiary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.trending_up_rounded, size: 20),
              text: 'Sales Report',
            ),
            Tab(
              icon: Icon(Icons.account_balance_rounded, size: 20),
              text: 'Cost Report',
            ),
            Tab(
              icon: Icon(Icons.monetization_on_rounded, size: 20),
              text: 'Profit Report',
            ),
            Tab(
              icon: Icon(Icons.compare_arrows_rounded, size: 20),
              text: 'Comparison',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesReportView(),
          CostReportView(),
          ProfitReportView(),
          SalesComparisonView(),
        ],
      ),
    );
  }
}
