import 'package:clinc/models/invoice.dart';
import 'package:clinc/providers/appointment_provider.dart';
import 'package:clinc/providers/invoice_provider.dart';
import 'package:clinc/models/expense.dart';
import 'package:clinc/providers/expense_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:teeth_selector/teeth_selector.dart';

import '../l10n/app_localizations.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import '../providers/patient_provider.dart';
import '../providers/treatment_provider.dart';

class TreatmentFormScreen extends StatefulWidget {
  final Treatment? treatment;
  final int? patientId;

  const TreatmentFormScreen({super.key, this.treatment, this.patientId});

  @override
  State<TreatmentFormScreen> createState() => _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends State<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPatientId;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentDetailsController;
  late TextEditingController _toothNumberController;
  late TextEditingController _agreedAmountController;
  late TextEditingController _expensesController;
  late TextEditingController _laboratoryNameController;
  late DateTime _treatmentDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.treatment?.patientId ?? widget.patientId;
    _diagnosisController =
        TextEditingController(text: widget.treatment?.diagnosis);
    _treatmentDetailsController =
        TextEditingController(text: widget.treatment?.treatmentDetails);
    _toothNumberController =
        TextEditingController(text: widget.treatment?.toothNumber);
    _agreedAmountController = TextEditingController(
        text: widget.treatment?.agreedAmount?.toStringAsFixed(2) ?? '');
    _expensesController = TextEditingController(
        text: widget.treatment?.expenses?.toStringAsFixed(2) ?? '');
    _laboratoryNameController =
        TextEditingController(text: widget.treatment?.laboratoryName);
    _treatmentDate = widget.treatment != null
        ? DateTime.parse(widget.treatment!.treatmentDate)
        : DateTime.now();
    _status = widget.treatment?.status ?? 'قيد التنفيذ';
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentDetailsController.dispose();
    _toothNumberController.dispose();
    _agreedAmountController.dispose();
    _expensesController.dispose();
    _laboratoryNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _treatmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _treatmentDate) {
      setState(() {
        _treatmentDate = picked;
      });
    }
  }

  void _openTeethSelection() async {
    final List<String> currentlySelected = _toothNumberController.text
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    List<String> tempSelectedTeeth = List.from(currentlySelected);

    final result = await showDialog<List<int>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.toothNumber),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: TeethSelector(
                  onChange: (selected) {
                    setState(() {
                      tempSelectedTeeth = selected;
                    });
                  },
                  multiSelect: false,
                  selectedColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(dialogContext)!.save),
              onPressed: () {
                final List<int> result = tempSelectedTeeth.map(int.parse).toList();
                Navigator.of(dialogContext).pop(result);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        result.sort();
        _toothNumberController.text = result.join(', ');
      });
    }
  }

  void _saveTreatment() async {
    if (_formKey.currentState!.validate()) {
      final treatmentProvider =
          Provider.of<TreatmentProvider>(context, listen: false);
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      final patientProvider =
          Provider.of<PatientProvider>(context, listen: false);
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      final treatmentToSave = Treatment(
        treatmentId: widget.treatment?.treatmentId,
        patientId: _selectedPatientId!,
        diagnosis:
            _diagnosisController.text.isEmpty ? null : _diagnosisController.text,
        treatmentDetails: _treatmentDetailsController.text.isEmpty
            ? null
            : _treatmentDetailsController.text,
        toothNumber: _toothNumberController.text.isEmpty
            ? null
            : _toothNumberController.text,
        agreedAmount: double.tryParse(_agreedAmountController.text),
        agreedAmountPaid: widget.treatment?.agreedAmountPaid ?? 0.0,
        treatmentDate: _treatmentDate.toIso8601String(),
        status: _status,
        expenses: double.tryParse(_expensesController.text),
        laboratoryName: _laboratoryNameController.text.isEmpty
            ? null
            : _laboratoryNameController.text,
      );

      if (widget.treatment == null) {
        final newTreatmentId =
            await treatmentProvider.addTreatment(treatmentToSave);

        final recentOpenInvoice =
            await invoiceProvider.findLatestOpenInvoice(_selectedPatientId!);

        if (recentOpenInvoice != null) {
          await invoiceProvider.addTreatmentToInvoice(
            patientId: _selectedPatientId!,
            treatmentId: newTreatmentId,
            invoiceId: recentOpenInvoice.invoiceId,
          );
        } else {
          // Force create a new invoice
          final newInvoice = Invoice(
            patientId: _selectedPatientId!,
            invoiceDate: DateTime.now().toIso8601String(),
            status: 'مسودة',
          );
          await invoiceProvider.addInvoice(newInvoice, [newTreatmentId]);
        }
      } else {
        await treatmentProvider.updateTreatment(treatmentToSave);
      }

      final double expenses = double.tryParse(_expensesController.text) ?? 0.0;
      if (expenses > 0.0) {
        final Patient patient = patientProvider.patients.firstWhere((p) => p.patientId == _selectedPatientId);
        final String description = '${patient.name} - ${_toothNumberController.text} - ${_treatmentDetailsController.text}';
        
        final newExpense = Expense(
          description: description,
          amount: expenses,
          expenseDate: _treatmentDate.toIso8601String(),
          category: 'patient_expenses',
        );
        await expenseProvider.addExpense(newExpense);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final patientProvider = Provider.of<PatientProvider>(context);

    Patient? selectedPatient;
    if (_selectedPatientId != null) {
      try {
        selectedPatient = patientProvider.patients
            .firstWhere((p) => p.patientId == _selectedPatientId);
      } catch (e) {
        selectedPatient = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treatment == null
            ? appLocalizations.addTreatment
            : appLocalizations.editTreatment),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 2000),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.patientId == null) ...[
                    DropdownSearch<Patient>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            hintText: appLocalizations.searchPatientsHint,
                          ),
                        ),
                        menuProps: const MenuProps(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      items: patientProvider.patients,
                      itemAsString: (Patient p) => p.name,
                      selectedItem: selectedPatient,
                      onChanged: (Patient? newValue) {
                        setState(() {
                          _selectedPatientId = newValue?.patientId;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: _inputDecoration(
                            appLocalizations.patientFormField, context),
                      ),
                      validator: (value) {
                        if (_selectedPatientId == null) {
                          return appLocalizations.pleaseSelectPatient;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextFormField(
                    controller: _diagnosisController,
                    decoration:
                        _inputDecoration(appLocalizations.diagnosis, context),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _treatmentDetailsController,
                    decoration: _inputDecoration(
                        appLocalizations.treatmentDetails, context),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _openTeethSelection,
                          child: InputDecorator(
                            decoration: _inputDecoration(
                                appLocalizations.toothNumber, context),
                            child: Text(
                              _toothNumberController.text.isEmpty
                                  ? appLocalizations.toothNumber
                                  : _toothNumberController.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextFormField(
                          controller: _agreedAmountController,
                          decoration: _inputDecoration(
                              appLocalizations.agreedAmount, context),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return appLocalizations.pleaseEnterValidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expensesController,
                          decoration:
                              _inputDecoration('تكاليف', context),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final expenses = double.tryParse(value);
                              if (expenses == null) {
                                return appLocalizations.pleaseEnterValidNumber;
                              }

                              final agreedAmount =
                                  double.tryParse(_agreedAmountController.text);

                              if (agreedAmount != null && expenses > agreedAmount) {
                                return 'التكاليف لا يمكن أن تكون أكبر من المبلغ المتفق عليه';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextFormField(
                          controller: _laboratoryNameController,
                          decoration: _inputDecoration(
                              'اسم المخبر', context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: _inputDecoration(
                              appLocalizations.statusFormField, context),
                          items: <String>['قيد التنفيذ', 'مكتمل', 'متابعة']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _status = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: _inputDecoration(
                                appLocalizations.date, context),
                            child: Text(
                              DateFormat.yMd(appLocalizations.localeName)
                                  .format(_treatmentDate),
                            ),
                          ),
                        ),
                      ),
                    ],
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
          onPressed: _saveTreatment,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.treatment == null
              ? appLocalizations.addTreatment
              : appLocalizations.updateTreatment),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}