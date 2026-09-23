import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';
import 'add_sale_screen.dart';

/// Tab view for Today's Sales.
class TodaySalesView extends StatelessWidget {
  const TodaySalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: "Today's Sales",
      subtitle: "Review all transactions recorded today, total daily revenue, items sold, and payment methods.",
      icon: Icons.today_rounded,
      color: AppColors.primary,
      features: const [
        'Real-time gross revenue total for today',
        'Breakdown by Cash, Debt, and Digital payments',
        'Quick receipt reprint and share',
        'Void / Refund transaction support',
      ],
      actionLabel: 'Record New Sale',
      actionIcon: Icons.add_rounded,
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddSaleScreen()),
        );
      },
    );
  }
}
