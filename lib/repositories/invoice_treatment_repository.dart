import '../models/invoice_treatment.dart';
import '../services/database_service.dart';

class InvoiceTreatmentRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertInvoiceTreatment(InvoiceTreatment invoiceTreatment) async {
    final db = await _databaseService.database;
    var map = invoiceTreatment.toMap();
    map.remove('id');
    return await db.insert(
      'Invoice_Treatments',
      map,
    );
  }

  Future<List<InvoiceTreatment>> getInvoiceTreatments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Invoice_Treatments');
    return List.generate(maps.length, (i) {
      return InvoiceTreatment.fromMap(maps[i]);
    });
  }

  Future<List<InvoiceTreatment>> getInvoiceTreatmentsByInvoiceId(int invoiceId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Invoice_Treatments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return List.generate(maps.length, (i) {
      return InvoiceTreatment.fromMap(maps[i]);
    });
  }

  Future<int> deleteInvoiceTreatment(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Invoice_Treatments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoiceTreatmentsByInvoiceId(int invoiceId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Invoice_Treatments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }
}
