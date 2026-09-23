import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Sales Comparison.
class SalesComparisonView extends StatelessWidget {
  const SalesComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Sales Comparison',
      subtitle: 'Compare sales growth across periods: Day vs Yesterday, Week vs Last Week, or Month vs Last Month.',
      icon: Icons.compare_arrows_rounded,
      color: AppColors.info,
      features: const [
        'Period-over-Period growth percentages (% Growth)',
        'Side-by-side bar chart comparison',
        'Customer traffic & average order value (AOV) comparison',
        'Seasonal trend insights and projection',
      ],
      actionLabel: 'Select Comparison Range',
      actionIcon: Icons.date_range_rounded,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Period comparison tool will be enabled in the reporting phase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
