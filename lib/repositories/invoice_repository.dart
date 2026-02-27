import '../models/invoice.dart';
import '../services/database_service.dart';

class InvoiceRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await _databaseService.database;
    var map = invoice.toMap();
    map.remove('invoice_id');
    return await db.insert(
      'Invoices',
      map,
    );
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Invoices');
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Invoices',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await _databaseService.database;
    return await db.update(
      'Invoices',
      invoice.toMap(),
      where: 'invoice_id = ?',
      whereArgs: [invoice.invoiceId],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Invoices',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
  }
    Future<int> deleteInvoicesByPatientId(int patientId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Invoices',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }
}



