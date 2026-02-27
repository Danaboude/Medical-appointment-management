import '../models/payment.dart';
import '../services/database_service.dart';

class PaymentRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertPayment(Payment payment) async {
    final db = await _databaseService.database;
    var map = payment.toMap();
    map.remove('payment_id');
    return await db.insert(
      'Payments',
      map,
    );
  }

  Future<List<Payment>> getPayments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('Payments');
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  Future<List<Payment>> getPaymentsByInvoiceId(int invoiceId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  Future<Payment?> getPaymentById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Payments',
      where: 'payment_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await _databaseService.database;
    return await db.update(
      'Payments',
      payment.toMap(),
      where: 'payment_id = ?',
      whereArgs: [payment.paymentId],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Payments',
      where: 'payment_id = ?',
      whereArgs: [id],
    );
  }
    Future<int> deletePayments(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Payments',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
  }
}
