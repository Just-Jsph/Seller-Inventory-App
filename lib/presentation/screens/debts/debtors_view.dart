import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';
import 'add_debt_screen.dart';

/// Tab view for Active Debtors.
class DebtorsView extends StatelessWidget {
  const DebtorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Active Debtors',
      subtitle: 'Manage customers with outstanding balances, view overdue amounts, and trigger payment reminders.',
      icon: Icons.people_alt_rounded,
      color: AppColors.warning,
      features: const [
        'List of all customers with unpaid balances',
        'Overdue indicators and days elapsed tracking',
        'Customer contact shortcut (SMS / Call / Share)',
        'Comprehensive debt history per customer',
      ],
      actionLabel: 'Add New Debt',
      actionIcon: Icons.add_rounded,
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddDebtScreen()),
        );
      },
    );
  }
}
