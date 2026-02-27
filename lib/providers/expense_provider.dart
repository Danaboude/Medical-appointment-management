import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _selectedCategoryKey;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get selectedCategoryKey => _selectedCategoryKey;

  ExpenseProvider() {
    fetchExpenses();
  }

  void setSelectedCategory(String? key) {
    _selectedCategoryKey = key;
    notifyListeners();
  }

  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();
    _expenses = await _expenseRepository.getExpenses();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseRepository.insertExpense(expense);
    await fetchExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseRepository.updateExpense(expense);
    await fetchExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _expenseRepository.deleteExpense(id);
    await fetchExpenses();
  }
}
