import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Placeholder sub-screen for recording a new sale.
class AddSaleScreen extends StatelessWidget {
  const AddSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sale'),
      ),
      body: PlaceholderView(
        title: 'New Sale Entry',
        subtitle: 'Record item sales, apply discounts, scan barcodes, and register payments (Cash, Transfer, Credit/Debt).',
        icon: Icons.add_shopping_cart_rounded,
        color: AppColors.primary,
        features: const [
          'Barcode / QR product scanning',
          'Multiple cart items selection',
          'Automatic stock deduction',
          'Payment method split (Cash, Debts, Bank)',
          'Instant receipt printing / sharing',
        ],
        actionLabel: 'Simulate Sale Completed',
        actionIcon: Icons.check_circle_outline_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale recorded (Placeholder). Inventory and calculations will be connected soon.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
