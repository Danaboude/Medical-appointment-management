import 'package:flutter/material.dart';
import '../models/treatment.dart';
import '../repositories/treatment_repository.dart';

class TreatmentProvider with ChangeNotifier {
  final TreatmentRepository _treatmentRepository = TreatmentRepository();
  List<Treatment> _treatments = [];
  bool _isLoading = false;

  List<Treatment> get treatments => _treatments;
  bool get isLoading => _isLoading;

  TreatmentProvider() {
    fetchTreatments();
  }

  Future<void> fetchTreatments() async {
    _isLoading = true;
    notifyListeners();
    _treatments = await _treatmentRepository.getTreatments();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addTreatment(Treatment treatment) async {
    final id = await _treatmentRepository.insertTreatment(treatment);
    await fetchTreatments();
    return id;
  }

  Future<void> updateTreatment(Treatment treatment) async {
    await _treatmentRepository.updateTreatment(treatment);
    await fetchTreatments();
  }

  Future<void> deleteTreatment(int id) async {
    await _treatmentRepository.deleteTreatment(id);
    await fetchTreatments();
  }

  Future<List<Treatment>> getTreatmentsByPatientId(int patientId) async {
    return await _treatmentRepository.getTreatmentsByPatientId(patientId);
  }

  Future<Treatment?> getTreatmentById(int id) async {
    return await _treatmentRepository.getTreatmentById(id);
  }

  // New method to update agreed_amount_paid for a treatment
  Future<void> updateTreatmentPaidAmount(int treatmentId, double amountPaid) async {
    await _treatmentRepository.updateTreatmentPaidAmount(treatmentId, amountPaid);
    // Find the treatment in the local list and update its paid amount
    final index = _treatments.indexWhere((t) => t.treatmentId == treatmentId);
    if (index != -1) {
      final updatedTreatment = _treatments[index].copyWith(agreedAmountPaid: amountPaid);
      _treatments[index] = updatedTreatment;
      notifyListeners();
    }
  }
}
