import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _expenseDate;
  late String _category;
  bool _isInit = true;

  final List<String> _categoryKeys = [
    'rent',
    'salaries',
    'patient_expenses',
        'medical_supplies',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.expense?.description);
    _amountController = TextEditingController(
        text: widget.expense?.amount.toStringAsFixed(2) ?? '');
    _expenseDate = widget.expense != null
        ? DateTime.parse(widget.expense!.expenseDate)
        : DateTime.now();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final appLocalizations = AppLocalizations.of(context)!;
      final categoryValue = widget.expense?.category;
      if (categoryValue == null) {
        _category = 'other';
      } else {
        final localizedToKeyMap = Map.fromEntries(_categoryKeys.map(
            (key) => MapEntry(_getLocalizedCategoryName(key, appLocalizations), key)));
        if (localizedToKeyMap.containsKey(categoryValue)) {
          _category = localizedToKeyMap[categoryValue]!;
        } else if (_categoryKeys.contains(categoryValue)) {
          _category = categoryValue;
        } else {
          _category = 'other';
        }
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

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

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expense(
        expenseId: widget.expense?.expenseId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: double.parse(_amountController.text),
        expenseDate: _expenseDate.toIso8601String(),
        category: _category,
      );

      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (widget.expense == null) {
        provider.addExpense(newExpense);
      } else {
        provider.updateExpense(newExpense);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null
            ? appLocalizations.addExpenseTitle
            : appLocalizations.editExpenseTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: inputDecoration.copyWith(
                        labelText: appLocalizations.descriptionFormField,
                        alignLabelWithHint: true),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: inputDecoration.copyWith(
                              labelText: appLocalizations.amount),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return appLocalizations.pleaseEnterAmount;
                            }
                            if (double.tryParse(value) == null) {
                              return appLocalizations.pleaseEnterValidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: inputDecoration.copyWith(
                                labelText: appLocalizations.date),
                            child: Text(
                                DateFormat.yMd(appLocalizations.localeName)
                                    .format(_expenseDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: inputDecoration.copyWith(
                        labelText: appLocalizations.categoryFormField),
                    items: _categoryKeys
                        .map<DropdownMenuItem<String>>((String key) {
                      final localizedName =
                          _getLocalizedCategoryName(key, appLocalizations);
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(localizedName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _category = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations.pleaseSelectCategory;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.expense == null
                        ? appLocalizations.addExpenseButton
                        : appLocalizations.updateExpenseButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
