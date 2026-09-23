import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/placeholder_view.dart';

/// Sub-screen for managing account profile and password.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: PlaceholderView(
        title: user != null ? 'Account: ${user.name}' : 'Account Settings',
        subtitle: 'Manage your credentials, change password, profile details, and account security.',
        icon: Icons.person_rounded,
        color: AppColors.primary,
        features: [
          'Logged in as: ${user?.username ?? "Unknown"} (User ID #${user?.id ?? 1})',
          'Full Name: ${user?.name ?? "N/A"}',
          'Multi-user isolated database session',
          'Change master password and security recovery',
        ],
        actionLabel: 'Update Profile (Placeholder)',
        actionIcon: Icons.edit_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile editor will be enabled in future releases.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
