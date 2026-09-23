import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'add_debt_screen.dart';
import 'debtors_view.dart';
import 'debt_payments_view.dart';

/// Main Debts hub containing Debtors, Add Debt action, and Debt Payments tabs.
class DebtsScreen extends StatefulWidget {
  final int initialTabIndex;

  const DebtsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Debts & Receivables'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.tertiary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_alt_rounded, size: 20),
              text: 'Debtors',
            ),
            Tab(
              icon: Icon(Icons.payments_rounded, size: 20),
              text: 'Payments',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DebtorsView(),
          DebtPaymentsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Debt'),
      ),
    );
  }
}
