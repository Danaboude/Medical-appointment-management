import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'dart:io'; // Added for Platform check
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Added for FFI initialization

import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/treatment_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/laboratory_provider.dart';

import 'screens/main_screen.dart';

void main() async {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().checkAndInsertInitialData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentProvider()),
        ChangeNotifierProxyProvider<TreatmentProvider, InvoiceProvider>(
          create: (_) => InvoiceProvider(),
          update: (_, treatmentProvider, invoiceProvider) =>
              invoiceProvider!..setTreatmentProvider(treatmentProvider),
        ),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => LaboratoryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            locale: settingsProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
                Locale('en', ''), // English
              Locale('ar', ''), // Arabic
            ],
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
