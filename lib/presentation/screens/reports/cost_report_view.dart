import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Cost Report.
class CostReportView extends StatelessWidget {
  const CostReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Cost & Expenses Report',
      subtitle: 'Analyze cost of goods sold (COGS), operational overheads, inventory purchases, and business expenses.',
      icon: Icons.account_balance_rounded,
      color: AppColors.error,
      features: const [
        'Cost of Goods Sold (COGS) analytics',
        'Categorized operating expenses (Rent, Utilities, Wages, Misc)',
        'Inventory procurement cost trends',
        'Expense vs Revenue ratio breakdowns',
      ],
      actionLabel: 'Export Cost Breakdown',
      actionIcon: Icons.file_download_outlined,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cost export will be active once expenses database is populated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
