import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Sub-screen for configuring debt interest rates and lending policies.
class InterestSettingsScreen extends StatelessWidget {
  const InterestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interest Settings'),
      ),
      body: PlaceholderView(
        title: 'Interest & Credit Policy',
        subtitle: 'Configure default interest rates for customer credit, compounding frequencies, and penalty policies.',
        icon: Icons.percent_rounded,
        color: AppColors.warning,
        features: const [
          'Default debt interest rate (% per month or year)',
          'Simple vs Compound interest calculation mode',
          'Grace period days before interest accrual begins',
          'Late payment penalty fee rules',
        ],
        actionLabel: 'Save Preferences (Placeholder)',
        actionIcon: Icons.save_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interest preferences will be saved once settings repository is linked.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
