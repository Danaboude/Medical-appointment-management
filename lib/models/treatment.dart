class Treatment {
  final int? treatmentId;
  final int patientId;
  final String? diagnosis;
  final String? treatmentDetails;
  final String? toothNumber;
  final double? agreedAmount;
  final double? agreedAmountPaid; // New field
  final String treatmentDate;
  final String status;
  final double? expenses;
  final String? laboratoryName;

  Treatment({
    this.treatmentId,
    required this.patientId,
    this.diagnosis,
    this.treatmentDetails,
    this.toothNumber,
    this.agreedAmount,
    this.agreedAmountPaid, // New field in constructor
    required this.treatmentDate,
    required this.status,
    this.expenses,
    this.laboratoryName,
  });

  // fromMap
  factory Treatment.fromMap(Map<String, dynamic> map) {
    return Treatment(
      treatmentId: map['treatment_id'],
      patientId: map['patient_id'],
      diagnosis: map['diagnosis'],
      treatmentDetails: map['treatment'],
      toothNumber: map['tooth_number'],
      agreedAmount: map['agreed_amount'],
      agreedAmountPaid: map['agreed_amount_paid'], // New field from map
      treatmentDate: map['treatment_date'],
      status: map['status'],
      expenses: map['expenses'],
      laboratoryName: map['laboratory_name'],
    );
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'treatment_id': treatmentId,
      'patient_id': patientId,
      'diagnosis': diagnosis,
      'treatment': treatmentDetails,
      'tooth_number': toothNumber,
      'agreed_amount': agreedAmount,
      'agreed_amount_paid': agreedAmountPaid, // New field to map
      'treatment_date': treatmentDate,
      'status': status,
      'expenses': expenses,
      'laboratory_name': laboratoryName,
    };
  }

  // copyWith
  Treatment copyWith({
    int? treatmentId,
    int? patientId,
    String? diagnosis,
    String? treatmentDetails,
    String? toothNumber,
    double? agreedAmount,
    double? agreedAmountPaid, // New field in copyWith
    String? treatmentDate,
    String? status,
    double? expenses,
    String? laboratoryName,
  }) {
    return Treatment(
      treatmentId: treatmentId ?? this.treatmentId,
      patientId: patientId ?? this.patientId,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentDetails: treatmentDetails ?? this.treatmentDetails,
      toothNumber: toothNumber ?? this.toothNumber,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      agreedAmountPaid: agreedAmountPaid ?? this.agreedAmountPaid, // New field in copyWith
      treatmentDate: treatmentDate ?? this.treatmentDate,
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      laboratoryName: laboratoryName ?? this.laboratoryName,
    );
  }
}