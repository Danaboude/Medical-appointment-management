import 'package:clinc/models/invoice_treatment.dart';
import 'package:clinc/models/treatment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/invoice.dart';
import '../models/patient.dart';
import '../providers/invoice_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/treatment_provider.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;

  final int? patientId;

  const InvoiceFormScreen({super.key, this.invoice,this.patientId});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPatientId;
  late DateTime _invoiceDate;
  late TextEditingController _totalAmountController;
  late String _status;
  List<int> _selectedTreatmentIds = [];
  List<InvoiceTreatment> _allInvoiceTreatments = [];
  double _paidAmount = 0.0;
  bool _isLoadingTreatments = true;

  final TextEditingController _patientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.invoice?.patientId;
    if(widget.patientId!=null) {
      _selectedPatientId=widget.patientId;
    }
    _invoiceDate = widget.invoice != null
        ? DateTime.parse(widget.invoice!.invoiceDate)
        : DateTime.now();
    _totalAmountController = TextEditingController(
        text: widget.invoice?.totalAmount?.toStringAsFixed(2) ?? '0.00');
    _status = widget.invoice?.status ?? 'مسودة';

    _loadAllInvoiceTreatments();

    if (widget.invoice != null) {
      Provider.of<InvoiceProvider>(context, listen: false)
          .getInvoiceTreatments(widget.invoice!.invoiceId!)
          .then((invoiceTreatments) {
        if (mounted) {
          setState(() {
            _selectedTreatmentIds =
                invoiceTreatments.map((it) => it.treatmentId).toList();
            _calculateTotalAmount();
          });
        }
      });
      _fetchPaidAmount();
    }

    _patientController.addListener(() {
      if (_selectedPatientId != null) {
        final patientProvider =
            Provider.of<PatientProvider>(context, listen: false);
        final selectedPatient = patientProvider.patients
            .firstWhere((p) => p.patientId == _selectedPatientId);
        if (_patientController.text != selectedPatient.name) {
          setState(() {
            _selectedPatientId = null;
            _selectedTreatmentIds.clear();
            _calculateTotalAmount();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _patientController.dispose();
    super.dispose();
  }

  void _loadAllInvoiceTreatments() async {
    final invoiceProvider =
        Provider.of<InvoiceProvider>(context, listen: false);
    final allTreatments = await invoiceProvider.getAllInvoiceTreatments();
    if (mounted) {
      setState(() {
        _allInvoiceTreatments = allTreatments;
        _isLoadingTreatments = false;
      });
    }
  }

  void _fetchPaidAmount() async {
    if (widget.invoice != null) {
      final payments =
          await Provider.of<InvoiceProvider>(context, listen: false)
              .getPaymentsForInvoice(widget.invoice!.invoiceId!);
      if (mounted) {
        setState(() {
          _paidAmount = payments.fold(0.0, (sum, p) => sum + p.amount);
        });
      }
    }
  }

  void _calculateTotalAmount() {
    final treatmentProvider =
        Provider.of<TreatmentProvider>(context, listen: false);
    double total = 0;
    for (var treatmentId in _selectedTreatmentIds) {
      final treatment = treatmentProvider.treatments
          .firstWhere((t) => t.treatmentId == treatmentId);
      final remaining =
          (treatment.agreedAmount ?? 0.0) - (treatment.agreedAmountPaid ?? 0.0);
      total += remaining;
    }
    if (mounted) {
      setState(() {
        _totalAmountController.text = total.toStringAsFixed(2);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {
      final newInvoice = Invoice(
        invoiceId: widget.invoice?.invoiceId,
        patientId: _selectedPatientId!,
        invoiceDate: _invoiceDate.toIso8601String(),
        totalAmount: double.tryParse(_totalAmountController.text),
        status: _status,
      );

      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      if (widget.invoice == null) {
        provider.addInvoice(newInvoice, _selectedTreatmentIds);
      } else {
        provider.updateInvoice(newInvoice, _selectedTreatmentIds);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null
            ? appLocalizations.addInvoice
            : appLocalizations.editInvoiceTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildWideLayout(context);
            } else {
              return _buildNarrowLayout(context);
            }
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 450,
          child: _buildFormFields(context),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildTreatmentsSelector(context),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormFields(context),
          const Divider(height: 32),
          SizedBox(
            height: 400, // Constrain height for the treatments list
            child: _buildTreatmentsSelector(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final patientProvider = Provider.of<PatientProvider>(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );

    if (_patientController.text.isEmpty && _selectedPatientId != null) {
      final patient = patientProvider.patients
          .firstWhere((p) => p.patientId == _selectedPatientId);
      if (patient != null) {
        _patientController.text = patient.name;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Autocomplete<Patient>(
          displayStringForOption: (Patient patient) => patient.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Patient>.empty();
            }
            return patientProvider.patients.where((Patient patient) {
              return patient.name
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (Patient selection) {
            setState(() {
              _selectedPatientId = selection.patientId;
              _patientController.text = selection.name;
              _selectedTreatmentIds.clear();
              _calculateTotalAmount();
            });
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (_patientController.text.isNotEmpty) {
              fieldTextEditingController.text = _patientController.text;
            }
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: inputDecoration.copyWith(
                  labelText: appLocalizations.patientFormField),
              validator: (value) {
                if (_selectedPatientId == null) {
                  return appLocalizations.pleaseSelectPatient;
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: inputDecoration.copyWith(
                labelText: appLocalizations.invoiceDateFormField),
            child: Text(DateFormat.yMd(appLocalizations.localeName)
                .format(_invoiceDate)),
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: inputDecoration.copyWith(
              labelText: appLocalizations.statusFormField),
          items: <String>['مسودة', 'مدفوعة جزئياً', 'مدفوعة بالكامل']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(getLocalizedInvoiceStatus(value, appLocalizations)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _status = newValue!;
            });
          },
        ),
        if (widget.invoice != null) ...[
          const SizedBox(height: 24),
          _buildAmountSummary(context),
        ],
      ],
    );
  }

  Widget _buildAmountSummary(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final remainingAmount = totalAmount - _paidAmount;
    final formattedTotal = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(totalAmount);
    final formattedPaid = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(_paidAmount);
    final formattedRemaining = NumberFormat.currency(
            locale: appLocalizations.localeName,
            symbol: appLocalizations.currencySymbol)
        .format(remainingAmount);

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

  Widget _buildTreatmentsSelector(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appLocalizations.linkedTreatments,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_selectedPatientId == null)
            Expanded(
              child: Center(
                child: Text(appLocalizations.pleaseSelectPatientFirst),
              ),
            )
          else
            _isLoadingTreatments
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: Consumer<TreatmentProvider>(
                      builder: (context, treatmentProvider, child) {
                        if (treatmentProvider.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final patientTreatments = treatmentProvider.treatments
                            .where((t) => t.patientId == _selectedPatientId)
                            .toList();

                        // Sort treatments: fully paid ones go to the end
                        patientTreatments.sort((a, b) {
                          final aRemaining = (a.agreedAmount ?? 0.0) -
                              (a.agreedAmountPaid ?? 0.0);
                          final bRemaining = (b.agreedAmount ?? 0.0) -
                              (b.agreedAmountPaid ?? 0.0);

                          final aIsFullyPaid = aRemaining <= 0;
                          final bIsFullyPaid = bRemaining <= 0;

                          if (aIsFullyPaid && !bIsFullyPaid) {
                            return 1; // a comes after b
                          } else if (!aIsFullyPaid && bIsFullyPaid) {
                            return -1; // a comes before b
                          } else {
                            return 0; // maintain original order or sort by something else
                          }
                        });

                        if (patientTreatments.isEmpty) {
                          return Center(
                              child: Text(
                                  appLocalizations.noTreatmentsForPatient));
                        }
                        return ListView.builder(
                          itemCount: patientTreatments.length,
                          itemBuilder: (context, index) {
                            final treatment = patientTreatments[index];
                            return _buildTreatmentTile(context, treatment);
                          },
                        );
                      },
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildTreatmentTile(BuildContext context, Treatment treatment) {
    final appLocalizations = AppLocalizations.of(context)!;

    InvoiceTreatment? invoiceTreatmentLink;
    try {
      invoiceTreatmentLink = _allInvoiceTreatments.firstWhere(
        (it) =>
            it.treatmentId == treatment.treatmentId &&
            it.invoiceId != widget.invoice?.invoiceId,
      );
    } catch (e) {
      invoiceTreatmentLink = null;
    }
    final isAlreadyInvoiced = invoiceTreatmentLink != null;

    // Calculate remaining amount
    final remainingAmount =
        (treatment.agreedAmount ?? 0.0) - (treatment.agreedAmountPaid ?? 0.0);
    final isFullyPaid = remainingAmount <= 0; // Check if fully paid or overpaid

    final isSelected = _selectedTreatmentIds.contains(treatment.treatmentId);
    final formattedAmount = NumberFormat.currency(
      locale: appLocalizations.localeName,
      symbol: appLocalizations.currencySymbol,
    ).format(remainingAmount); // Display remaining amount

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(treatment.diagnosis ?? 'N/A'),
        subtitle: Text(
          isAlreadyInvoiced
              ? appLocalizations.treatmentAlreadyInvoiced(invoiceTreatmentLink.invoiceId)
              : (isFullyPaid
                  ? appLocalizations.fullyPaid
                  : formattedAmount), // Show "Fully Paid" or remaining amount
          style: TextStyle(
            color: isFullyPaid
                ? Colors.green
                : (isAlreadyInvoiced ? Colors.red.shade700 : null),
            fontWeight: isFullyPaid || isAlreadyInvoiced ? FontWeight.bold : null,
          ),
        ),
        value: isSelected,
        onChanged: (isAlreadyInvoiced ||
                isFullyPaid) // Disable if already invoiced or fully paid
            ? null
            : (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedTreatmentIds.add(treatment.treatmentId!);
                  } else {
                    _selectedTreatmentIds.remove(treatment.treatmentId);
                  }
                  _calculateTotalAmount();
                });
              },
        activeColor: Theme.of(context).primaryColor,
        secondary: (isAlreadyInvoiced ||
                isFullyPaid) // Show lock icon for disabled treatments
            ? const Icon(Icons.lock, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final formattedTotal = NumberFormat.currency(
      locale: appLocalizations.localeName,
      symbol: appLocalizations.currencySymbol,
    ).format(totalAmount);

    return BottomAppBar(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 8), // Reduced vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  SizedBox(height: 100,),
                Text(appLocalizations.totalAmount,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 14)),
                Text(
                  formattedTotal,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _saveInvoice,
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.invoice == null
                  ? appLocalizations.addInvoice
                  : appLocalizations.updateInvoiceButton),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
