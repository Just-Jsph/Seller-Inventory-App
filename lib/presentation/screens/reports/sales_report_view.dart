import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Sales Report.
class SalesReportView extends StatelessWidget {
  const SalesReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Sales Report',
      subtitle: 'Comprehensive breakdown of sales volumes, revenue streams, best-selling items, and daily peaks.',
      icon: Icons.trending_up_rounded,
      color: AppColors.info,
      features: const [
        'Interactive bar & line charts of revenue over time',
        'Top 10 best-selling items by revenue and quantity',
        'Hourly / Daily sales peak analysis',
        'Export to Excel (CSV) and formatted PDF report',
      ],
      actionLabel: 'Export Sales Summary',
      actionIcon: Icons.file_download_outlined,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report export engine will be available in the reporting module.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
