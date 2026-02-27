import './patient.dart';
import './treatment.dart';

class LaboratoryItem {
  final Patient patient;
  final Treatment treatment;
  String note;

  LaboratoryItem({required this.patient, required this.treatment, this.note = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaboratoryItem &&
          runtimeType == other.runtimeType &&
          patient.patientId == other.patient.patientId &&
          treatment.treatmentId == other.treatment.treatmentId;

  @override
  int get hashCode => patient.patientId.hashCode ^ treatment.treatmentId.hashCode;
}
