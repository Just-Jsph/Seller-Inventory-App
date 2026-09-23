import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Tab view for Debt Payments and Collections.
class DebtPaymentsView extends StatelessWidget {
  const DebtPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Debt Payments & Collections',
      subtitle: 'Record full or partial customer repayments, track balance reductions, and issue payment receipts.',
      icon: Icons.payments_rounded,
      color: AppColors.warning,
      features: const [
        'Record partial or full balance payments',
        'Automatic balance updates and status progression (Paid/Partial)',
        'Payment method tracking (Cash, Bank, GCash/E-Wallet)',
        'Receipt generation and payment confirmation logs',
      ],
      actionLabel: 'Log Payment Receipt',
      actionIcon: Icons.receipt_rounded,
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment collector form will be enabled in the debt management phase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
