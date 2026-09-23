import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Sub-screen for configuring business store information, currency, and receipts.
class BusinessSettingsScreen extends StatelessWidget {
  const BusinessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
      ),
      body: PlaceholderView(
        title: 'Store & Business Profile',
        subtitle: 'Configure store branding, currency symbol, receipt headers, tax identification, and contact info.',
        icon: Icons.store_rounded,
        color: AppColors.secondary,
        features: const [
          'Business Name & Store Tagline',
          'Currency Symbol (e.g. ₱, \$, €, etc.) and decimal places',
          'Receipt Header & Footer message customization',
          'Default Tax / VAT rate configuration',
          'Business Address & Phone details for invoices',
        ],
        actionLabel: 'Save Store Settings (Placeholder)',
        actionIcon: Icons.save_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business profile stored locally (Placeholder).'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
