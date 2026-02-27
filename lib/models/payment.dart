class Payment {
  int? paymentId;
  int invoiceId;
  double amount;
  String paymentDate; // Stored as ISO 8601 string
  String method; // e.g., 'نقدي', 'بطاقة', 'تحويل'

  Payment({
    this.paymentId,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.method = 'نقدي',
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate,
      'method': method,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'],
      invoiceId: map['invoice_id'],
      amount: map['amount'],
      paymentDate: map['payment_date'],
      method: map['method'],
    );
  }
}
