import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.more),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(24.0),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        children: [
          _MoreItem(
            icon: Icons.money_off,
            title: appLocalizations.expenses,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesScreen()),
              );
            },
          ),
          _MoreItem(
            icon: Icons.bar_chart,
            title: appLocalizations.reports,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          _MoreItem(
            icon: Icons.settings,
            title: appLocalizations.settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}