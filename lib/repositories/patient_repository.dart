import '../models/patient.dart';
import '../services/database_service.dart';

class PatientRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertPatient(Patient patient) async {
    final db = await _databaseService.database;
    var map = patient.toMap();
    map.remove('patient_id');
    return await db.insert(
      'Patients',
      map,
    );
  }

  Future<List<Patient>> getPatients() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Patients');
    return List.generate(maps.length, (i) {
      return Patient.fromMap(maps[i]);
    });
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Patients',
      where: 'patient_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await _databaseService.database;
    return await db.update(
      'Patients',
      patient.toMap(),
      where: 'patient_id = ?',
      whereArgs: [patient.patientId],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Patients',
      where: 'patient_id = ?',
      whereArgs: [id],
    );
  }
}
