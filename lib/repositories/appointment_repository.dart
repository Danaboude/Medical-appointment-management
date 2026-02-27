import '../models/appointment.dart';
import '../services/database_service.dart';

class AppointmentRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await _databaseService.database;
    var map = appointment.toMap();
    map.remove('appointment_id');
    return await db.insert(
      'Appointments',
      map,
    );
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Appointments');
    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  Future<Appointment?> getAppointmentById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Appointments',
      where: 'appointment_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await _databaseService.database;
    return await db.update(
      'Appointments',
      appointment.toMap(),
      where: 'appointment_id = ?',
      whereArgs: [appointment.appointmentId],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Appointments',
      where: 'appointment_id = ?',
      whereArgs: [id],
    );
  }
    Future<int> deleteAppointmentsByPatientId(int patientId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Appointments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }
}



