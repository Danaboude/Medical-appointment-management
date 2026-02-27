import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/appointment_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/treatment_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _exportData(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.exportingData)));

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                  content: Text(appLocalizations.storagePermissionRequired)),
            );
          return;
        }
      }

      final String? outputDirectory =
          await FilePicker.platform.getDirectoryPath(
        dialogTitle: appLocalizations.selectExportDirectory,
      );

      if (outputDirectory == null) {
        // User canceled the picker
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      final backupService = BackupService();
      final tempFilePath = await backupService.exportData();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (tempFilePath != null) {
        final tempFile = File(tempFilePath);
        final fileName = path.basename(tempFile.path);
        final newPath = path.join(outputDirectory, fileName);

        await tempFile.copy(newPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLocalizations.exportSuccessful} $newPath'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.backupFailed)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.backupFailed}: $e')),
        );
    }
  }

  void _importData(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.restoreWarningTitle),
        content: Text(appLocalizations.restoreWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.restore,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.importingData)));

    final backupService = BackupService();
    final success = await backupService.importData();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (success) {
      // Reload all data after import
      await Future.wait([
        Provider.of<PatientProvider>(context, listen: false).fetchPatients(),
        Provider.of<AppointmentProvider>(context, listen: false)
            .fetchAppointments(),
        Provider.of<TreatmentProvider>(context, listen: false)
            .fetchTreatments(),
        Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices(),
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.restoreSuccessful)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.restoreFailed)),
      );
    }
  }

  void _resetApp(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.resetAppWarningTitle),
        content: Text(appLocalizations.resetAppWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.reset,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocalizations.resettingApp)));

    try {
      await DatabaseService().clearDatabase();

      // Reload all data after clearing
      await Future.wait([
        Provider.of<PatientProvider>(context, listen: false).fetchPatients(),
        Provider.of<AppointmentProvider>(context, listen: false)
            .fetchAppointments(),
        Provider.of<TreatmentProvider>(context, listen: false)
            .fetchTreatments(),
        Provider.of<InvoiceProvider>(context, listen: false).fetchInvoices(),
        Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(),
      ]);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(appLocalizations.resetAppSuccess)),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${appLocalizations.resetAppFailed}: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.settings),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle(context, appLocalizations.dataManagement),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file_outlined),
                      title: Text(appLocalizations.exportData),
                      subtitle: Text(appLocalizations.exportDataSubtitle),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: Text(appLocalizations.importData),
                      subtitle: Text(appLocalizations.importDataSubtitle),
                      onTap: () => _importData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error),
                      title: Text(
                        appLocalizations.resetApp,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      subtitle: Text(appLocalizations.resetAppSubtitle),
                      onTap: () => _resetApp(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, AppLocalizations appLocalizations) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(appLocalizations.language),
      trailing: DropdownButton<String>(
        value: settingsProvider.locale.languageCode,
        underline: const SizedBox.shrink(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            settingsProvider.setLanguage(newValue);
          }
        },
        items:
            <String>['en', 'ar'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value == 'en'
                ? appLocalizations.english
                : appLocalizations.arabic),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeTile(
      BuildContext context, AppLocalizations appLocalizations) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return SwitchListTile(
      secondary: const Icon(Icons.brightness_6_outlined),
      title: Text(appLocalizations.theme),
      value: settingsProvider.themeMode == ThemeMode.dark,
      onChanged: (bool value) {
        settingsProvider.toggleTheme(value);
      },
    );
  }
}
