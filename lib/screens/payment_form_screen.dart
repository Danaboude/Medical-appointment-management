import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/payment.dart';
import '../providers/invoice_provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final Payment? payment;
  final int invoiceId;

  const PaymentFormScreen({super.key, this.payment, required this.invoiceId});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late DateTime _paymentDate;
  late String _method;

  double _remainingAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.payment?.amount.toStringAsFixed(2) ?? '');
    _paymentDate = widget.payment != null
        ? DateTime.parse(widget.payment!.paymentDate)
        : DateTime.now();
    _method = widget.payment?.method ?? 'نقدي';
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    final invoice = invoiceProvider.invoices
        .firstWhere((inv) => inv.invoiceId == widget.invoiceId);
    final payments =
        await invoiceProvider.getPaymentsForInvoice(widget.invoiceId);
    final paidAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

    if (mounted) {
      setState(() {
        _remainingAmount = (invoice.totalAmount ?? 0.0) - paidAmount;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _savePayment() {
    if (_formKey.currentState!.validate()) {
      final newPayment = Payment(
        paymentId: widget.payment?.paymentId,
        invoiceId: widget.invoiceId,
        amount: double.parse(_amountController.text),
        paymentDate: _paymentDate.toIso8601String(),
        method: _method,
      );

      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      if (widget.payment == null) {
        provider.addPayment(newPayment);
      } else {
        // Update is not typically done for payments, but you could implement it here.
        // provider.updatePayment(newPayment);
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment == null
            ? appLocalizations.addPayment
            : appLocalizations.editPaymentTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInvoiceSummary(context),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _amountController,
                          decoration: _inputDecoration(
                              appLocalizations.amount, context),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return appLocalizations.pleaseEnterAmount;
                            }
                            final amount = double.tryParse(value);
                            if (amount == null) {
                              return appLocalizations.pleaseEnterValidNumber;
                            }
                            if (amount <= 0) {
                              return appLocalizations.amountCannotBeZero;
                            }
                            if (amount > _remainingAmount) {
                              final formattedRemaining = NumberFormat.currency(
                                      locale: appLocalizations.localeName,
                                      symbol: appLocalizations.currencySymbol)
                                  .format(_remainingAmount);
                              return '${appLocalizations.amountExceedsRemaining} $formattedRemaining';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _method,
                          decoration: _inputDecoration(
                              appLocalizations.method, context),
                          items: <String>['نقدي', 'بطاقة', 'تحويل']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(getLocalizedPaymentMethod(value, appLocalizations)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _method = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: _inputDecoration(
                                appLocalizations.date, context),
                            child: Text(
                              DateFormat.yMd(appLocalizations.localeName)
                                  .format(_paymentDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInvoiceSummary(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    final invoice = invoiceProvider.invoices
        .firstWhere((inv) => inv.invoiceId == widget.invoiceId);
    final totalAmount = invoice.totalAmount ?? 0.0;
    final paidAmount = totalAmount - _remainingAmount;

    final formattedTotal = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(totalAmount);
    final formattedPaid = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(paidAmount);
    final formattedRemaining = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(_remainingAmount);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
                context, appLocalizations.totalAmount, formattedTotal),
            const SizedBox(height: 8),
            _buildSummaryRow(
                context, appLocalizations.paidAmount, formattedPaid),
            const Divider(height: 24),
            _buildSummaryRow(
                context, appLocalizations.remainingAmount, formattedRemaining,
                isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value,
      {bool isHighlight = false}) {
    final textTheme = Theme.of(context).textTheme;
    final style = isHighlight
        ? textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary)
        : textTheme.titleMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyLarge),
        Text(value, style: style),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return BottomAppBar(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _savePayment,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.payment == null
              ? appLocalizations.addPayment
              : appLocalizations.updatePaymentButton),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
