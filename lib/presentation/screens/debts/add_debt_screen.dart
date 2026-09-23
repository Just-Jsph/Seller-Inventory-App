import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Placeholder sub-screen for adding a new debt or debtor record.
class AddDebtScreen extends StatelessWidget {
  const AddDebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Debt'),
      ),
      body: PlaceholderView(
        title: 'Register New Debt',
        subtitle: 'Issue credit or loans to customers, record item sales on credit, and configure interest terms.',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.warning,
        features: const [
          'Select or create debtor customer profile',
          'Principal debt amount and attached items',
          'Due date selection & reminder notes',
          'Interest rate calculation type (Fixed, Monthly %)',
          'Instant customer statement generation',
        ],
        actionLabel: 'Simulate Debt Created',
        actionIcon: Icons.check_circle_outline_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debt logged (Placeholder). Ledger calculations will be enabled in the debts module.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
