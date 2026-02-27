import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertExpense(Expense expense) async {
    final db = await _databaseService.database;
    var map = expense.toMap();
    map.remove('expense_id');
    return await db.insert(
      'Expenses',
      map,
    );
  }

  Future<List<Expense>> getExpenses() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Expenses');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Expenses',
      where: 'expense_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await _databaseService.database;
    return await db.update(
      'Expenses',
      expense.toMap(),
      where: 'expense_id = ?',
      whereArgs: [expense.expenseId],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Expenses',
      where: 'expense_id = ?',
      whereArgs: [id],
    );
  }
}
