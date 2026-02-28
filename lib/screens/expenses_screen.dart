import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _getLocalizedCategoryName(String categoryKey, AppLocalizations l10n) {
    switch (categoryKey) {
      case 'rent':
        return l10n.expenseCategoryRent;
      case 'salaries':
        return l10n.expenseCategorySalaries;
      case 'patient_expenses':
        return l10n.patientExpenses;
      case 'medical_supplies':
        return l10n.expenseCategoryMedicalSupplies;
      case 'other':
        return l10n.expenseCategoryOther;
      default:
        return categoryKey;
    }
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'rent':
        return Icons.house_outlined;
      case 'salaries':
        return Icons.payments_outlined;
      case 'medical_supplies':
        return Icons.medical_services_outlined;
      case 'patient_expenses':
        return Icons.person_outline;
      case 'other':
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.expenses),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Column(
            children: [
              Expanded(
                child: Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, child) {
                    if (expenseProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allExpenses = expenseProvider.expenses;
                    if (allExpenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(appLocalizations.noExpensesForCategory,
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      );
                    }

                    final Map<String, List<Expense>> groupedExpenses = {};
                    for (var expense in allExpenses) {
                      groupedExpenses
                          .putIfAbsent(expense.category, () => [])
                          .add(expense);
                    }

                    final selectedCategory =
                        expenseProvider.selectedCategoryKey;
                    final categoriesToShow = selectedCategory != null
                        ? [selectedCategory]
                        : groupedExpenses.keys.toList()
                      ..sort((a, b) => _getLocalizedCategoryName(
                              a, appLocalizations)
                          .compareTo(
                              _getLocalizedCategoryName(b, appLocalizations)));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: categoriesToShow.length,
                      itemBuilder: (context, index) {
                        final categoryKey = categoriesToShow[index];
                        final categoryExpenses =
                            groupedExpenses[categoryKey] ?? [];
                        categoryExpenses.sort((a, b) =>
                            DateTime.parse(b.expenseDate)
                                .compareTo(DateTime.parse(a.expenseDate)));

                        final categoryTotal = categoryExpenses.fold(
                            0.0, (sum, e) => sum + e.amount);

                        final formattedTotal = NumberFormat.currency(
                          locale: appLocalizations.localeName,
                          symbol: appLocalizations.currencySymbol,
                        ).format(categoryTotal);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                              child: Icon(
                                _getCategoryIcon(categoryKey),
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            title: Text(
                              _getLocalizedCategoryName(
                                  categoryKey, appLocalizations),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${appLocalizations.totalLabel}: $formattedTotal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            children: categoryExpenses.map((expense) {
                              final formattedAmount = NumberFormat.currency(
                                locale: appLocalizations.localeName,
                                symbol: appLocalizations.currencySymbol,
                              ).format(expense.amount);
                              return ListTile(
                                title: Text(DateFormat.yMd(
                                        appLocalizations.localeName)
                                    .format(
                                        DateTime.parse(expense.expenseDate))),
                                trailing: Text(formattedAmount),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExpenseFormScreen(expense: expense),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseFormScreen()),
          );
        },
        tooltip: appLocalizations.addExpenseTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
