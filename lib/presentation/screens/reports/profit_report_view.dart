import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Profit Report.
class ProfitReportView extends StatelessWidget {
  const ProfitReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Profit & Margins Report',
      subtitle: 'Evaluate Gross Profit, Net Profit, operating profit margins, and itemized profitability.',
      icon: Icons.monetization_on_rounded,
      color: AppColors.success,
      features: const [
        'Gross Profit = Total Revenue - COGS',
        'Net Profit = Gross Profit - Operating Expenses',
        'Itemized product profit margin ranking',
        'Monthly & Annual Profitability projections',
      ],
      actionLabel: 'Export Profit Statement',
      actionIcon: Icons.file_download_outlined,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profit calculations engine will be connected in the analytics phase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
