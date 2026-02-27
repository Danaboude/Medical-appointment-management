import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../repositories/patient_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/treatment_repository.dart';

class PatientProvider with ChangeNotifier {
  final PatientRepository _patientRepository = PatientRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final TreatmentRepository _treatmentRepository = TreatmentRepository();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Patient> get patients => _filteredPatients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  PatientProvider() {
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();
    _patients = await _patientRepository.getPatients();
    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPatient(Patient patient) async {
    final tempPatient = Patient(
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      address: patient.address,
      phone: patient.phone,
      maritalStatus: patient.maritalStatus,
      fileNumber: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary
      firstVisitDate: patient.firstVisitDate,
      xrayImage: patient.xrayImage,
    );
    final id = await _patientRepository.insertPatient(tempPatient);
    final finalPatient = Patient(
      patientId: id,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      address: patient.address,
      phone: patient.phone,
      maritalStatus: patient.maritalStatus,
      fileNumber: id.toString(),
      firstVisitDate: patient.firstVisitDate,
      xrayImage: patient.xrayImage,
    );
    await _patientRepository.updatePatient(finalPatient);
    await fetchPatients();
  }

  Future<void> updatePatient(Patient patient) async {
    await _patientRepository.updatePatient(patient);
    await fetchPatients();
  }

  Future<void> deletePatient(int id) async {
    await _patientRepository.deletePatient(id);
    await fetchPatients();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPatients = _patients;
    } else {
      _filteredPatients = _patients.where((patient) {
        return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               patient.fileNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (patient.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }
}
