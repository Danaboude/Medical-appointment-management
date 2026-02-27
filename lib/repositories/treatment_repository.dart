import '../models/treatment.dart';
import '../services/database_service.dart';

class TreatmentRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertTreatment(Treatment treatment) async {
    final db = await _databaseService.database;
    var map = treatment.toMap();
    map.remove('treatment_id');
    // Ensure agreed_amount_paid is set to 0.0 for new treatments if not provided
    map['agreed_amount_paid'] ??= 0.0;
    return await db.insert(
      'Treatments',
      map,
    );
  }

  Future<List<Treatment>> getTreatments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Treatments');
    return List.generate(maps.length, (i) {
      return Treatment.fromMap(maps[i]);
    });
  }

  Future<List<Treatment>> getTreatmentsByPatientId(int patientId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Treatments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'treatment_date DESC',
    );
    return List.generate(maps.length, (i) {
      return Treatment.fromMap(maps[i]);
    });
  }

  Future<Treatment?> getTreatmentById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Treatments',
      where: 'treatment_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Treatment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTreatment(Treatment treatment) async {
    final db = await _databaseService.database;
    return await db.update(
      'Treatments',
      treatment.toMap(),
      where: 'treatment_id = ?',
      whereArgs: [treatment.treatmentId],
    );
  }

  // New method to update agreed_amount_paid
  Future<int> updateTreatmentPaidAmount(int treatmentId, double amountPaid) async {
    final db = await _databaseService.database;
    return await db.update(
      'Treatments',
      {'agreed_amount_paid': amountPaid},
      where: 'treatment_id = ?',
      whereArgs: [treatmentId],
    );
  }

  Future<int> deleteTreatment(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Treatments',
      where: 'treatment_id = ?',
      whereArgs: [id],
    );
  }
    Future<int> deleteTreatmentsByPatientId(int patientId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Treatments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }
}



