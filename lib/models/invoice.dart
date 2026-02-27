class Invoice {
  int? invoiceId;
  int patientId;
  String invoiceDate; // Stored as ISO 8601 string
  double? totalAmount;
  String status; // e.g., 'مسودة', 'مدفوعة جزئياً', 'مدفوعة بالكامل'

  Invoice({
    this.invoiceId,
    required this.patientId,
    required this.invoiceDate,
    this.totalAmount,
    this.status = 'مسودة',
  });
    Invoice copyWith({
    int? invoiceId,
    int? patientId,
    String? invoiceDate,
    double? totalAmount,
    String? status,
  }) {
    return Invoice(
      invoiceId: invoiceId ?? this.invoiceId,
      patientId: patientId ?? this.patientId,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_id': invoiceId,
      'patient_id': patientId,
      'invoice_date': invoiceDate,
      'total_amount': totalAmount,
      'status': status,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      invoiceId: map['invoice_id'],
      patientId: map['patient_id'],
      invoiceDate: map['invoice_date'],
      totalAmount: map['total_amount'],
      status: map['status'],
    );
  }
}
