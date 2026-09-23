import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'add_sale_screen.dart';
import 'today_sales_view.dart';
import 'sales_history_view.dart';

/// Main Sales hub containing Today's Sales, Add Sale action, and Sales History tabs.
class SalesScreen extends StatefulWidget {
  final int initialTabIndex;

  const SalesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
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
        title: const Text('Sales Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.tertiary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.today_rounded, size: 20),
              text: "Today's Sales",
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'Sales History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TodaySalesView(),
          SalesHistoryView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddSaleScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Sale'),
      ),
    );
  }
}
