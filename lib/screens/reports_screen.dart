import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/expense_provider.dart';
import '../providers/invoice_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.reports),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Consumer2<InvoiceProvider, ExpenseProvider>(
        builder: (context, invoiceProvider, expenseProvider, child) {
          if (invoiceProvider.isLoading || expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<_FinancialMetrics>(
            future: _calculateMetrics(invoiceProvider, expenseProvider, appLocalizations),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final metrics = snapshot.data!;
                return LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFinancialOverview(
                                context, metrics, appLocalizations),
                            const SizedBox(height: 40),
                            _buildCharts(
                                context, constraints, metrics, appLocalizations),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              }
              return const SizedBox.shrink(); // Should not happen
            },
          );
        },
      ),
    );
  }

  Future<_FinancialMetrics> _calculateMetrics(
      InvoiceProvider invoiceProvider,
      ExpenseProvider expenseProvider,
      AppLocalizations l10n) async {
    // Define statuses for revenue-generating invoices
    const revenueStatuses = ['مدفوعة بالكامل', 'Paid', 'مدفوعة جزئياً'];

    // Calculate Revenue: Sum of totalAmount for fully and partially paid invoices
    double totalRevenue = 0.0;
    for (var invoice in invoiceProvider.invoices) {
      if (revenueStatuses.contains(invoice.status)) {
        if (invoice.status == 'مدفوعة جزئياً') {
          // Fetch payments for this invoice
          final payments = await invoiceProvider.getPaymentsForInvoice(invoice.invoiceId!);
          final paidAmountForThisInvoice = payments.fold(0.0, (paymentSum, payment) => paymentSum + payment.amount);
          totalRevenue += paidAmountForThisInvoice;
        } else {
          totalRevenue += (invoice.totalAmount ?? 0.0);
        }
      }
    }

    // Calculate Expenses
    double totalExpenses = expenseProvider.expenses
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate Outstanding Invoices: Sum of totalAmount for draft invoices
    double outstandingInvoices = invoiceProvider.invoices
        .where((invoice) => invoice.status == 'مسودة')
        .fold(0.0, (sum, invoice) => sum + (invoice.totalAmount ?? 0.0));

    // Calculate Net Income
    final netIncome = totalRevenue - totalExpenses;

    // Calculate Invoice Counts
    final totalInvoicesCount = invoiceProvider.invoices.length;
    final paidInvoicesCount = invoiceProvider.invoices
        .where((invoice) => revenueStatuses.contains(invoice.status))
        .length;

    // Expense Breakdown Pie Chart Data
    Map<String, double> expenseByCategory = {};
    for (var expense in expenseProvider.expenses) {
      final categoryName = _getLocalizedCategoryName(expense.category, l10n);
      expenseByCategory.update(categoryName, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    // Revenue Trend Line Chart Data
    Map<String, double> revenueByWeek = {};
    invoiceProvider.invoices
        .where((invoice) => revenueStatuses.contains(invoice.status))
        .forEach((invoice) {
      final date = DateTime.parse(invoice.invoiceDate);
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(startOfWeek);

      revenueByWeek.update(
          weekKey, (value) => value + (invoice.totalAmount ?? 0.0),
          ifAbsent: () => invoice.totalAmount ?? 0.0);
    });

    List<String> sortedWeeks = revenueByWeek.keys.toList()..sort();

    List<FlSpot> revenueSpots = [];
    for (int j = 0; j < sortedWeeks.length; j++) {
      revenueSpots.add(FlSpot(j.toDouble(), revenueByWeek[sortedWeeks[j]]!));
    }

    return _FinancialMetrics(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      outstandingInvoices: outstandingInvoices,
      netIncome: netIncome,
      totalInvoicesCount: totalInvoicesCount,
      paidInvoicesCount: paidInvoicesCount,
      expenseByCategory: expenseByCategory,
      revenueSpots: revenueSpots,
      revenueWeekLabels: sortedWeeks,
    );
  }

  Widget _buildFinancialOverview(
      BuildContext context, _FinancialMetrics metrics, AppLocalizations l10n) {
    final currencyFormat = NumberFormat.currency(
        locale: l10n.localeName, symbol: l10n.currencySymbol, decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financialOverview,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.5,
          children: [
            ReportCard(
              title: l10n.totalRevenue,
              value: currencyFormat.format(metrics.totalRevenue),
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            ReportCard(
              title: l10n.totalExpenses,
              value: currencyFormat.format(metrics.totalExpenses),
              icon: Icons.trending_down,
              color: Colors.red,
            ),
            ReportCard(
              title: l10n.outstandingInvoices,
              value: currencyFormat.format(metrics.outstandingInvoices),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
            ),
            ReportCard(
              title: l10n.netIncome,
              value: currencyFormat.format(metrics.netIncome),
              icon: Icons.attach_money,
              color: Colors.blueGrey,
            ),
            ReportCard(
              title: l10n.totalInvoices,
              value: metrics.totalInvoicesCount.toString(),
              icon: Icons.receipt_long,
              color: Colors.purple,
            ),
            ReportCard(
              title: l10n.paidInvoices,
              value: metrics.paidInvoicesCount.toString(),
              icon: Icons.check_circle,
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharts(BuildContext context, BoxConstraints constraints,
      _FinancialMetrics metrics, AppLocalizations l10n) {
    if (constraints.maxWidth > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPieChart(context, metrics, l10n)),
          const SizedBox(width: 24),
          Expanded(child: _buildLineChart(context, metrics, l10n)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildPieChart(context, metrics, l10n),
          const SizedBox(height: 40),
          _buildLineChart(context, metrics, l10n),
        ],
      );
    }
  }

  Widget _buildPieChart(
      BuildContext context, _FinancialMetrics metrics, AppLocalizations l10n) {
    final List<Color> pieColors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400
    ];
    int i = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseBreakdown,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: metrics.expenseByCategory.isEmpty
              ? Center(child: Text(l10n.noExpensesForCategory))
              : PieChart(
                  PieChartData(
                    sections: metrics.expenseByCategory.entries.map((entry) {
                      final color = pieColors[i++ % pieColors.length];
                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title:
                            '${(entry.value / metrics.totalExpenses * 100).toStringAsFixed(0)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2)
                            ]),
                      );
                    }).toList(),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: metrics.expenseByCategory.keys.map((category) {
            final color = pieColors[
                metrics.expenseByCategory.keys.toList().indexOf(category) %
                    pieColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: color),
                const SizedBox(width: 8),
                Text(category),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildLineChart(
      BuildContext context, _FinancialMetrics metrics, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.revenueTrend,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: metrics.revenueSpots.isEmpty
              ? Center(child: Text(l10n.notEnoughDataForTrend))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() <
                                metrics.revenueWeekLabels.length) {
                              final weekKey = metrics.revenueWeekLabels[value.toInt()];
                              final date = DateFormat('yyyy-MM-dd').parse(weekKey);
                              final label = DateFormat('dd/MM').format(date);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(label,
                                    style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: metrics.revenueSpots,
                        isCurved: true,
                        color: Theme.of(context).primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _getLocalizedCategoryName(String categoryKey, AppLocalizations l10n) {
    switch (categoryKey) {
      case 'rent':
        return l10n.expenseCategoryRent;
      case 'salaries':
        return l10n.expenseCategorySalaries;
      case 'medical_supplies':
        return l10n.expenseCategoryMedicalSupplies;
      case 'patient_expenses':
        return l10n.patientExpenses;
      case 'other':
      default:
        return l10n.expenseCategoryOther;
    }
  }
}

class ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ReportCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialMetrics {
  final double totalRevenue;
  final double totalExpenses;
  final double outstandingInvoices;
  final Map<String, double> expenseByCategory;
  final List<FlSpot> revenueSpots;
  final List<String> revenueWeekLabels;

  final double netIncome;
  final int totalInvoicesCount;
  final int paidInvoicesCount;

  _FinancialMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.outstandingInvoices,
    required this.expenseByCategory,
    required this.revenueSpots,
    required this.revenueWeekLabels,
    required this.netIncome,
    required this.totalInvoicesCount,
    required this.paidInvoicesCount,
  });
}
