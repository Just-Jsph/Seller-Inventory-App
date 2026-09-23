import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'account_settings_screen.dart';
import 'interest_settings_screen.dart';
import 'business_settings_screen.dart';
import 'backup_restore_screen.dart';

/// Main Settings screen with links to Account, Interest Settings, Business Settings, Backup/Restore, and Logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Your business data will remain safely stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            // User Header Tile
            if (user != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Settings Group Header: Management
            _buildSectionHeader(context, 'Configuration'),

            // 1. Account Settings
            _buildSettingTile(
              context: context,
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              title: 'Account',
              subtitle: 'Profile details, password, and security',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                );
              },
            ),

            // 2. Interest Settings
            _buildSettingTile(
              context: context,
              icon: Icons.percent_rounded,
              iconColor: AppColors.warning,
              title: 'Interest Settings',
              subtitle: 'Default debt interest rates and loan policies',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InterestSettingsScreen()),
                );
              },
            ),

            // 3. Business Settings
            _buildSettingTile(
              context: context,
              icon: Icons.store_mall_directory_outlined,
              iconColor: AppColors.secondary,
              title: 'Business Settings',
              subtitle: 'Store name, currency, taxes, and receipt format',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessSettingsScreen()),
                );
              },
            ),

            const SizedBox(height: 16),
            // Settings Group Header: Maintenance
            _buildSectionHeader(context, 'Data & Security'),

            // 4. Backup & Restore
            _buildSettingTile(
              context: context,
              icon: Icons.backup_outlined,
              iconColor: AppColors.info,
              title: 'Backup/Restore',
              subtitle: 'Export and import local SQLite database',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // 5. Logout Tile
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              color: AppColors.error.withValues(alpha: 0.05),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.error),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                subtitle: const Text(
                  'End your current session safely',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        onTap: onTap,
      ),
    );
  }
}
