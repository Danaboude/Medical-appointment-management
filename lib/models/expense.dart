class Expense {
  int? expenseId;
  String? description;
  double amount;
  String expenseDate; // Stored as ISO 8601 string
  String category; // e.g., 'إيجار', 'رواتب', 'مواد طبية', 'أخرى'

  Expense({
    this.expenseId,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.category = 'أخرى',
  });

  Map<String, dynamic> toMap() {
    return {
      'expense_id': expenseId,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate,
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expense_id'],
      description: map['description'],
      amount: map['amount'],
      expenseDate: map['expense_date'],
      category: map['category'],
    );
  }
}
