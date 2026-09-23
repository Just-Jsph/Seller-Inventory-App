import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/placeholder_view.dart';

/// Sub-screen for backing up and restoring business database files.
class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: PlaceholderView(
        title: 'Database Backup & Restore',
        subtitle: 'Export encrypted local backups of your store database or restore existing backup files safely.',
        icon: Icons.settings_backup_restore_rounded,
        color: AppColors.info,
        features: const [
          'Manual full database backup export (.db / .json)',
          'Restore database from local storage or cloud drive',
          'Scheduled automatic daily backups',
          'Secure offline-first data retention',
        ],
        actionLabel: 'Create Immediate Backup',
        actionIcon: Icons.backup_rounded,
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup created (Placeholder). Local storage export will be activated in maintenance tools.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
