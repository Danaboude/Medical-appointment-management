class Appointment {
  int? appointmentId;
  int patientId;
  String appointmentDate; // Stored as ISO 8601 string
  String? notes;
  String? doctorNotes;
  String status; // e.g., 'محجوز', 'ملغي', 'منجز'

  Appointment({
    this.appointmentId,
    required this.patientId,
    required this.appointmentDate,
    this.notes,
    this.doctorNotes,
    this.status = 'محجوز',
  });

  Map<String, dynamic> toMap() {
    return {
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'appointment_date': appointmentDate,
      'notes': notes,
      'doctor_notes': doctorNotes,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      appointmentId: map['appointment_id'],
      patientId: map['patient_id'],
      appointmentDate: map['appointment_date'],
      notes: map['notes'],
      doctorNotes: map['doctor_notes'],
      status: map['status'],
    );
  }
}
