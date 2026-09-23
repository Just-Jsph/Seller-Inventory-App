import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Sales History.
class SalesHistoryView extends StatelessWidget {
  const SalesHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Sales History',
      subtitle: 'Filter and browse complete sales records by custom date range, customer, payment status, or receipt #.',
      icon: Icons.history_rounded,
      color: AppColors.primary,
      features: const [
        'Custom date range picker (Daily, Weekly, Monthly, Custom)',
        'Search by receipt number or customer name',
        'Filter by payment mode (Cash, Credit/Debt, Bank)',
        'Export history to CSV and PDF',
      ],
      actionLabel: 'Filter Date Range',
      actionIcon: Icons.date_range_rounded,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date filter selector will be activated in the reporting phase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
