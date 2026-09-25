import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/database_helper.dart';

/// Sub-screen for backing up and restoring business database files.
class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  Future<void> _exportBackup(BuildContext context) async {
    try {
      // Get current DB path
      final db = await DatabaseHelper().database;
      final dbPath = db.path;

      // Prepare backup file path in documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('${docDir.path}/backup_$timestamp.db');
      await backupFile.writeAsBytes(await File(dbPath).readAsBytes());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created at ${backupFile.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (result == null || result.files.isEmpty) return;
      final selectedFile = File(result.files.single.path!);

      // Simple validation: ensure it's a non‑empty SQLite file
      if (await selectedFile.length() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected file is empty or invalid.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Restoring will replace the current database.\nAll unsaved changes will be lost. Continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Restore')),
          ],
        ),
      );
      if (confirm != true) return;

      // Close existing DB connection
      final helper = DatabaseHelper();
      await helper.close();

      // Replace the DB file
      final db = await helper.database; // this will recreate if missing
      final dbPath = db.path;
      await File(dbPath).delete();
      await selectedFile.copy(dbPath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database restored successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.backup_rounded, color: AppColors.info),
              title: const Text('Export Backup'),
              subtitle: const Text('Create a local copy of the SQLite database'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _exportBackup(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.restore_rounded, color: AppColors.success),
              title: const Text('Import Backup'),
              subtitle: const Text('Restore database from a previously exported file'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _importBackup(context),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Backup files are stored in the app\'s documents directory.\nYou can copy them elsewhere for safety.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

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
