import 'package:clinc/models/invoice_treatment.dart';
import 'package:clinc/models/treatment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clinc/services/pdf_invoice_service.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../providers/invoice_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/treatment_provider.dart';
import 'payment_form_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  // Key to trigger refresh of FutureBuilders
  Key _futureBuilderKey = UniqueKey();

  void _refreshData() {
    setState(() {
      _futureBuilderKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations.invoice} #${widget.invoice.invoiceId}'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final appLocalizations = AppLocalizations.of(context)!;
              final patientProvider =
                  Provider.of<PatientProvider>(context, listen: false);
              final invoiceProvider =
                  Provider.of<InvoiceProvider>(context, listen: false);
              final treatmentProvider =
                  Provider.of<TreatmentProvider>(context, listen: false);

              final patient = patientProvider.patients.firstWhere(
                (p) => p.patientId == widget.invoice.patientId,
                orElse: () => throw Exception(appLocalizations.patientNotFound),
              );

              final invoiceTreatments = await invoiceProvider
                  .getInvoiceTreatments(widget.invoice.invoiceId!);
              final payments = await invoiceProvider
                  .getPaymentsForInvoice(widget.invoice.invoiceId!);

              final pdfBytes = await PdfInvoiceService.generateInvoicePdf(
                widget.invoice,
                patient,
                invoiceTreatments,
                treatmentProvider.treatments,
                payments,
                appLocalizations,
              );

              final pdfPath = await PdfInvoiceService.savePdf(
                  'invoice_${widget.invoice.invoiceId}', pdfBytes);

              // // Share via WhatsApp
              // final phoneNumber = patient.phone;
              // if (phoneNumber != null && phoneNumber.isNotEmpty) {
              //   final whatsappUrl =
              //       "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(appLocalizations.invoicePdfMessage)}";
              //   if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
              //     await launchUrl(Uri.parse(whatsappUrl));
              //   } else {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //           content: Text(appLocalizations.whatsappNotInstalled)),
              //     );
              //   }
              // } else {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //         content:
              //             Text(appLocalizations.patientPhoneNumberMissing)),
              //   );
              // }

              // Also share the PDF file
              await Share.shareXFiles([XFile(pdfPath)],
                  text: appLocalizations.invoicePdfMessage);
            },
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildWideLayout(context);
        } else {
          return _buildNarrowLayout(context);
        }
      }),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: _buildInvoiceDetailsCard(context),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTreatmentsList(context)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Expanded(child: _buildPaymentsList(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInvoiceDetailsCard(context),
            const SizedBox(height: 24),
            _buildTreatmentsList(context, isScrollable: false),
            const SizedBox(height: 24),
            _buildPaymentsList(context, isScrollable: false),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsCard(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);

    final patient = patientProvider.patients.firstWhere(
      (p) => p.patientId == widget.invoice.patientId,
      orElse: () => throw Exception(appLocalizations.patientNotFound),
    );

    return FutureBuilder<List<Payment>>(
        future:
            invoiceProvider.getPaymentsForInvoice(widget.invoice.invoiceId!),
        key: _futureBuilderKey, // Use the key here
        builder: (context, snapshot) {
          final payments = snapshot.data ?? [];
          final paidAmount = payments.fold(0.0, (sum, p) => sum + p.amount);
          final totalAmount = widget.invoice.totalAmount ?? 0.0;
          final remainingAmount = totalAmount - paidAmount;

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
              .format(remainingAmount);

          return Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      context,
                      Icons.calendar_today_outlined,
                      appLocalizations.invoiceDate,
                      DateFormat.yMd(appLocalizations.localeName)
                          .format(DateTime.parse(widget.invoice.invoiceDate))),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, Icons.receipt_long_outlined,
                      appLocalizations.status, widget.invoice.status),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                      context, appLocalizations.totalAmount, formattedTotal),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      context, appLocalizations.paidAmount, formattedPaid),
                  const Divider(height: 24),
                  _buildSummaryRow(context, appLocalizations.remainingAmount,
                      formattedRemaining,
                      isHighlight: true),
                ],
              ),
            ),
          );
        });
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

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text('$label: ', style: Theme.of(context).textTheme.titleMedium),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentsList(BuildContext context,
      {bool isScrollable = true}) {
    final appLocalizations = AppLocalizations.of(context)!;
    final treatmentProvider =
        Provider.of<TreatmentProvider>(context, listen: false);
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.linkedTreatments,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: isScrollable ? 1 : 0,
          child: FutureBuilder<List<InvoiceTreatment>>(
            future:
                invoiceProvider.getInvoiceTreatments(widget.invoice.invoiceId!),
            key: _futureBuilderKey, // Use the key here
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child:
                        Text('${appLocalizations.error}: ${snapshot.error}'));
              }
              final invoiceTreatments = snapshot.data ?? [];
              if (invoiceTreatments.isEmpty) {
                return Center(child: Text(appLocalizations.noLinkedTreatments));
              }

              final allTreatments = treatmentProvider.treatments;
              final linkedTreatments = allTreatments.where((treatment) {
                return invoiceTreatments
                    .any((it) => it.treatmentId == treatment.treatmentId);
              }).toList();

              if (linkedTreatments.isEmpty) {
                return Center(
                    child: Text(appLocalizations.noLinkedTreatmentsFound));
              }

              return ListView.builder(
                shrinkWrap: !isScrollable,
                physics:
                    isScrollable ? null : const NeverScrollableScrollPhysics(),
                itemCount: linkedTreatments.length,
                itemBuilder: (context, index) {
                  final treatment = linkedTreatments[index];
                  return _buildTreatmentTile(treatment, appLocalizations);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList(BuildContext context, {bool isScrollable = true}) {
    final appLocalizations = AppLocalizations.of(context)!;
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    final isFullyPaid =
        ['مدفوعة بالكامل', 'Paid'].contains(widget.invoice.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appLocalizations.payments,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!isFullyPaid)
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentFormScreen(
                          invoiceId: widget.invoice.invoiceId!),
                    ),
                  );
                  _refreshData(); // Refresh data after returning
                },
                icon: const Icon(Icons.add),
                label: Text(appLocalizations.addPayment),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: isScrollable ? 1 : 0,
          child: FutureBuilder<List<Payment>>(
            future: invoiceProvider
                .getPaymentsForInvoice(widget.invoice.invoiceId!),
            key: _futureBuilderKey, // Use the key here
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child:
                        Text('${appLocalizations.error}: ${snapshot.error}'));
              }
              final payments = snapshot.data ?? [];
              if (payments.isEmpty) {
                return Center(child: Text(appLocalizations.noPaymentsFound));
              }
              return ListView.builder(
                shrinkWrap: !isScrollable,
                physics:
                    isScrollable ? null : const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return _buildPaymentTile(payment, payments, appLocalizations);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditPaymentDialog(
      Payment payment, List<Payment> allPayments) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final amountController =
        TextEditingController(text: payment.amount.toStringAsFixed(2));
    DateTime selectedDate = DateTime.parse(payment.paymentDate);

    final totalPaid = allPayments.fold(0.0, (sum, p) => sum + p.amount);
    final remainingAmount = (widget.invoice.totalAmount ?? 0.0) - totalPaid;
    final maxAllowedAmount = remainingAmount + payment.amount;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.editPayment),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.amount,
                        prefixText: '${appLocalizations.currencySymbol} ',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return appLocalizations.pleaseEnterAmount;
                        }
                        final amount = double.tryParse(value);
                        if (amount == null) {
                          return appLocalizations.pleaseEnterValidNumber;
                        }
                        if (amount <= 0) {
                          return appLocalizations.amountMustBePositive;
                        }
                        // Add a small tolerance for floating point comparisons
                        if (amount > maxAllowedAmount + 0.001) {
                          final formattedMax = NumberFormat.currency(
                            locale: appLocalizations.localeName,
                            symbol: appLocalizations.currencySymbol,
                          ).format(maxAllowedAmount);
                          return '${appLocalizations.amountExceedsRemaining} ($formattedMax)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(appLocalizations.paymentDate),
                      subtitle: Text(DateFormat.yMd(appLocalizations.localeName)
                          .format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appLocalizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newAmount = double.parse(amountController.text);
                  final updatedPayment = Payment(
                    paymentId: payment.paymentId,
                    invoiceId: payment.invoiceId,
                    amount: newAmount,
                    paymentDate: selectedDate.toIso8601String(),
                    method: payment.method,
                  );

                  try {
                    await invoiceProvider.updatePayment(updatedPayment);
                    Navigator.pop(dialogContext);
                    _refreshData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${appLocalizations.errorUpdatingPayment}: $e')),
                    );
                  }
                }
              },
              child: Text(appLocalizations.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentTile(
      Treatment treatment, AppLocalizations appLocalizations) {
    final formattedAmount = NumberFormat.currency(
      locale: appLocalizations.localeName,
      symbol: appLocalizations.currencySymbol,
    ).format(treatment.agreedAmount ?? 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(treatment.diagnosis ?? appLocalizations.noDiagnosis),
        subtitle: Text(
            '${appLocalizations.date}: ${DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(treatment.treatmentDate))}'),
        trailing: Text(formattedAmount,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPaymentTile(Payment payment, List<Payment> allPayments,
      AppLocalizations appLocalizations) {
    final formattedAmount = NumberFormat.currency(
      locale: appLocalizations.localeName,
      symbol: appLocalizations.currencySymbol,
    ).format(payment.amount);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(_getPaymentMethodIcon(payment.method)),
        title: Text(formattedAmount,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${appLocalizations.date}: ${DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(payment.paymentDate))}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(payment.method),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _showEditPaymentDialog(payment, allPayments);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'نقداً':
        return Icons.money_outlined;
      case 'credit card':
      case 'بطاقة ائتمان':
        return Icons.credit_card_outlined;
      case 'bank transfer':
      case 'تحويل بنكي':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_outlined;
    }
  }
}
