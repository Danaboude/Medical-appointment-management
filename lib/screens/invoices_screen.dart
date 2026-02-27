import 'package:clinc/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late TextEditingController _searchController;
  late InvoiceProvider _invoiceProvider;

  @override
  void initState() {
    super.initState();
    _invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    _searchController = TextEditingController(text: _invoiceProvider.searchQuery);
    _invoiceProvider.addListener(_onInvoiceProviderChanged);
    _searchController.addListener(() {
      if (_invoiceProvider.searchQuery != _searchController.text) {
        _invoiceProvider.setSearchQuery(_searchController.text);
      }
    });
  }

  void _onInvoiceProviderChanged() {
    if (_searchController.text != _invoiceProvider.searchQuery) {
      _searchController.text = _invoiceProvider.searchQuery;
    }
  }

  @override
  void dispose() {
    _invoiceProvider.removeListener(_onInvoiceProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.invoices),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Consumer2<InvoiceProvider, PatientProvider>(
        builder: (context, invoiceProvider, patientProvider, child) {
          if (invoiceProvider.isLoading || patientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final patientMap = {
            for (var p
                in patientProvider.patients.where((p) => p.patientId != null))
              p.patientId!: p.name
          };

          final filteredInvoices = invoiceProvider.invoices.where((invoice) {
            if (invoiceProvider.searchQuery.isEmpty) {
              return true;
            }
            final patientName =
                patientMap[invoice.patientId]?.toLowerCase() ?? '';
            final invoiceId = invoice.invoiceId.toString();
            final query = invoiceProvider.searchQuery.toLowerCase();

            return patientName.contains(query) || invoiceId.contains(query);
          }).toList();

          if (filteredInvoices.isEmpty && invoiceProvider.searchQuery.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(appLocalizations.noInvoicesFound,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.search,
                    hintText: appLocalizations.searchInvoicesHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surface.withAlpha(10),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return _buildDataTable(context, filteredInvoices,
                        appLocalizations, constraints, patientMap);
                  } else {
                    return _buildListView(context, filteredInvoices,
                        appLocalizations, patientMap);
                  }
                }),
              ),
            ],
          );
        },
      ),
     
    );
  }

  Widget _buildListView(BuildContext context, List<Invoice> invoices,
      AppLocalizations appLocalizations, Map<int, String> patientMap) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final patientName = patientMap[invoice.patientId] ?? '';
        final formattedAmount = NumberFormat.currency(
          locale: appLocalizations.localeName,
          symbol: appLocalizations.currencySymbol,
        ).format(invoice.totalAmount ?? 0);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceDetailScreen(invoice: invoice),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${appLocalizations.invoice} #${invoice.invoiceId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(invoice.status),
                        backgroundColor:
                            _getStatusColor(context, invoice.status)
                                .withOpacity(0.2),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(patientName),
                  const SizedBox(height: 4),
                  Text(DateFormat.yMd(appLocalizations.localeName)
                      .format(DateTime.parse(invoice.invoiceDate))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(formattedAmount,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
      BuildContext context,
      List<Invoice> invoices,
      AppLocalizations appLocalizations,
      BoxConstraints constraints,
      Map<int, String> patientMap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 32.0),
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 20,
              horizontalMargin: 16,
              dataRowHeight: 56,
              headingRowHeight: 56,
              headingRowColor: MaterialStateProperty.all(
                  colorScheme.primary.withOpacity(0.05)),
              dividerThickness: 1,
              columns: [
                DataColumn(
                    label: Text(appLocalizations.invoiceId,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(appLocalizations.patient,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(appLocalizations.date,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(appLocalizations.total,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    numeric: true),
                DataColumn(
                    label: Text(appLocalizations.status,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Center(
                        child: Text(appLocalizations.actions,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)))),
              ],
              rows: List.generate(invoices.length, (index) {
                final invoice = invoices[index];
                final patientName = patientMap[invoice.patientId] ?? '';
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return colorScheme.primary.withOpacity(0.15);
                    }
                    if (states.contains(MaterialState.hovered)) {
                      return colorScheme.primary.withOpacity(0.08);
                    }
                    return index.isEven
                        ? Colors.transparent
                        : colorScheme.surface.withAlpha(10);
                  }),
                  onSelectChanged: (isSelected) {
                    if (isSelected ?? false) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                InvoiceDetailScreen(invoice: invoice)),
                      );
                    }
                  },
                  cells: [
                    DataCell(Text(invoice.invoiceId.toString())),
                    DataCell(Text(patientName)),
                    DataCell(Text(DateFormat.yMd(appLocalizations.localeName)
                        .format(DateTime.parse(invoice.invoiceDate)))),
                    DataCell(Text(NumberFormat.currency(
                      locale: appLocalizations.localeName,
                      symbol: appLocalizations.currencySymbol,
                    ).format(invoice.totalAmount ?? 0))),
                    DataCell(Chip(
                      label: Text(invoice.status),
                      backgroundColor: _getStatusColor(context, invoice.status)
                          .withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      labelStyle: theme.textTheme.bodySmall,
                    )),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.visibility_outlined, size: 20),
                            tooltip: appLocalizations.viewInvoice,
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        InvoiceDetailScreen(invoice: invoice))),
                          ),
                   
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                  context, appLocalizations, () {
                                Provider.of<InvoiceProvider>(context,
                                        listen: false)
                                    .deleteInvoice(invoice.invoiceId!);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppLocalizations appLocalizations, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
          content: Text(appLocalizations.deletePatientConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.delete),
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'مدفوعة بالكامل':
      case 'Paid':
        return Colors.green;
      case 'مدفوعة جزئياً':
      case 'Partially Paid':
        return Colors.orange;
      case 'مسودة':
      case 'Draft':
      default:
        return Colors.grey;
    }
  }
}
