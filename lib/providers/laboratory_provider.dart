import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import '../repositories/patient_repository.dart';
import '../repositories/treatment_repository.dart';
import '../models/laboratory_item.dart';

class LaboratoryProvider with ChangeNotifier {
  final PatientRepository _patientRepository = PatientRepository();
  final TreatmentRepository _treatmentRepository = TreatmentRepository();

  List<LaboratoryItem> _items = [];
  List<LaboratoryItem> _filteredItems = [];
  List<LaboratoryItem> _selectedItems = [];
  final Map<LaboratoryItem, TextEditingController> _noteControllers = {};
  bool _isLoading = false;
  String _searchQuery = '';

  List<LaboratoryItem> get items => _filteredItems;
  List<LaboratoryItem> get selectedItems => _selectedItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    final patients = await _patientRepository.getPatients();
    final treatments = await _treatmentRepository.getTreatments();

    _items = treatments.map((treatment) {
      final patient = patients.firstWhere((p) => p.patientId == treatment.patientId, orElse: () => Patient(patientId: 0, name: 'Unknown', fileNumber: ''));
      final item = LaboratoryItem(patient: patient, treatment: treatment, note: treatment.treatmentDetails ?? '');
      _noteControllers[item] = TextEditingController(text: item.note);
      return item;
    }).toList();

    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = _items;
    } else {
      _filteredItems = _items.where((item) {
        return item.patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (item.treatment.treatmentDetails?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (item.treatment.toothNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void selectItem(LaboratoryItem item, bool isSelected) {
    if (isSelected) {
      _selectedItems.add(item);
    } else {
      _selectedItems.remove(item);
    }
    notifyListeners();
  }

  void selectAll(bool isSelected) {
    if (isSelected) {
      _selectedItems = List.from(_filteredItems);
    } else {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  bool areAllSelected() {
    if (_filteredItems.isEmpty) return false;
    return _selectedItems.length == _filteredItems.length;
  }

  TextEditingController? getNoteController(LaboratoryItem item) {
    return _noteControllers[item];
  }

  void updateNote(LaboratoryItem item, String newNote) {
    item.note = newNote;
    notifyListeners();
  }

  @override
  void dispose() {
    _noteControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
