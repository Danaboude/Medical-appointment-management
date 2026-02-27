class InvoiceTreatment {
  int? id;
  int invoiceId;
  int treatmentId;

  InvoiceTreatment({
    this.id,
    required this.invoiceId,
    required this.treatmentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'treatment_id': treatmentId,
    };
  }

  factory InvoiceTreatment.fromMap(Map<String, dynamic> map) {
    return InvoiceTreatment(
      id: map['id'],
      invoiceId: map['invoice_id'],
      treatmentId: map['treatment_id'],
    );
  }
}