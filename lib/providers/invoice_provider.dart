import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/invoice_treatment.dart';
import '../models/payment.dart';
import '../models/treatment.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/invoice_treatment_repository.dart';
import '../repositories/payment_repository.dart';
import 'treatment_provider.dart'; // Import TreatmentProvider

class InvoiceProvider with ChangeNotifier {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final InvoiceTreatmentRepository _invoiceTreatmentRepository =
      InvoiceTreatmentRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  // TreatmentProvider will be injected or accessed via Provider.of
  late TreatmentProvider _treatmentProvider;

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  InvoiceProvider() {
    // This constructor is called before the context is available for Provider.of
    // So, _treatmentProvider will be initialized in fetchInvoices or other methods
    fetchInvoices();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Method to set TreatmentProvider after context is available
  void setTreatmentProvider(TreatmentProvider provider) {
    _treatmentProvider = provider;
  }

  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();
    _invoices = await _invoiceRepository.getInvoices();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateInvoiceStatus(int invoiceId) async {
    // Ensure _treatmentProvider is initialized
    if (!(_treatmentProvider is TreatmentProvider)) {
      // This should ideally be initialized via Provider.of in a widget tree
      // For direct calls, ensure it's set or handle gracefully.
      // In a real app, you might pass context or ensure provider is available.
      print("TreatmentProvider not set in InvoiceProvider.");
      return;
    }

    final linkedTreatments = await _invoiceTreatmentRepository.getInvoiceTreatmentsByInvoiceId(invoiceId);
    List<Treatment> treatments = [];
    for (var lt in linkedTreatments) {
      final treatment = await _treatmentProvider.getTreatmentById(lt.treatmentId);
      if (treatment != null) {
        treatments.add(treatment);
      }
    }

    double totalAgreedAmount = treatments.fold(0.0, (sum, t) => sum + (t.agreedAmount ?? 0.0));
    double totalPaidForTreatments = treatments.fold(0.0, (sum, t) => sum + (t.agreedAmountPaid ?? 0.0));

    String newStatus;
    if (totalPaidForTreatments >= totalAgreedAmount) {
      newStatus = 'مدفوعة بالكامل';
    } else if (totalPaidForTreatments > 0) {
      newStatus = 'مدفوعة جزئياً';
    } else {
      newStatus = 'مسودة';
    }

    // Update invoice total_amount and status in DB
    final invoice = await _invoiceRepository.getInvoiceById(invoiceId);
    if (invoice != null) {
      final updatedInvoice = invoice.copyWith(
        totalAmount: totalAgreedAmount,
        status: newStatus,
      );
      await _invoiceRepository.updateInvoice(updatedInvoice);
    }
    await fetchInvoices(); // Refresh the list
  }

  Future<void> addInvoice(Invoice invoice, List<int> treatmentIds) async {
    // Calculate total_amount based on selected treatments' agreedAmount
    double calculatedTotalAmount = 0.0;
    if (!(_treatmentProvider is TreatmentProvider)) {
      print("TreatmentProvider not set in InvoiceProvider.");
      // Fallback or error handling
    } else {
      for (var id in treatmentIds) {
        final treatment = await _treatmentProvider.getTreatmentById(id);
        if (treatment != null) {
          calculatedTotalAmount += (treatment.agreedAmount ?? 0.0);
        }
      }
    }

    final newInvoice = invoice.copyWith(
      totalAmount: calculatedTotalAmount,
      status: 'مسودة', // Initial status
    );

    final newInvoiceId = await _invoiceRepository.insertInvoice(newInvoice);
    for (var treatmentId in treatmentIds) {
      await _invoiceTreatmentRepository.insertInvoiceTreatment(
        InvoiceTreatment(invoiceId: newInvoiceId, treatmentId: treatmentId),
      );
    }
    await _updateInvoiceStatus(newInvoiceId); // Update status after linking treatments
  }

  Future<void> updateInvoice(Invoice invoice, List<int> treatmentIds) async {
    // Calculate total_amount based on selected treatments' agreedAmount
    double calculatedTotalAmount = 0.0;
    if (!(_treatmentProvider is TreatmentProvider)) {
      print("TreatmentProvider not set in InvoiceProvider.");
      // Fallback or error handling
    } else {
      for (var id in treatmentIds) {
        final treatment = await _treatmentProvider.getTreatmentById(id);
        if (treatment != null) {
          calculatedTotalAmount += (treatment.agreedAmount ?? 0.0);
        }
      }
    }

    final updatedInvoice = invoice.copyWith(
      totalAmount: calculatedTotalAmount,
      // Status will be updated by _updateInvoiceStatus
    );

    await _invoiceRepository.updateInvoice(updatedInvoice);
    await _invoiceTreatmentRepository
        .deleteInvoiceTreatmentsByInvoiceId(invoice.invoiceId!);
    for (var treatmentId in treatmentIds) {
      await _invoiceTreatmentRepository.insertInvoiceTreatment(
        InvoiceTreatment(invoiceId: invoice.invoiceId!, treatmentId: treatmentId),
      );
    }
    await _updateInvoiceStatus(invoice.invoiceId!); // Update status after linking treatments
  }

  Future<void> deleteInvoice(int id) async {
    await _paymentRepository.deletePayments(id);
    await _invoiceTreatmentRepository.deleteInvoiceTreatmentsByInvoiceId(id);
    // Payments are deleted via ON DELETE CASCADE in the database schema
    await _invoiceRepository.deleteInvoice(id);
    await fetchInvoices();
  }
    Future<void> deleteoneInvoice(int id) async {
    await _paymentRepository.deletePayments(id);
    await _invoiceTreatmentRepository.deleteInvoiceTreatmentsByInvoiceId(id);
    // Payments are deleted via ON DELETE CASCADE in the database schema
    await _invoiceRepository.deleteInvoice(id);
    await fetchInvoices();
  }

  Future<List<InvoiceTreatment>> getInvoiceTreatments(int invoiceId) async {
    return await _invoiceTreatmentRepository
        .getInvoiceTreatmentsByInvoiceId(invoiceId);
  }

  Future<List<InvoiceTreatment>> getAllInvoiceTreatments() async {
    return await _invoiceTreatmentRepository.getInvoiceTreatments();
  }

  Future<void> addPayment(Payment payment) async {
    await _paymentRepository.insertPayment(payment);
    await _rebalancePaymentsForInvoice(payment.invoiceId);
    notifyListeners();
  }

  Future<void> updatePayment(Payment payment) async {
    await _paymentRepository.updatePayment(payment);
    await _rebalancePaymentsForInvoice(payment.invoiceId);
    notifyListeners();
  }

  Future<void> _rebalancePaymentsForInvoice(int invoiceId) async {
    if (!(_treatmentProvider is TreatmentProvider)) {
      print("TreatmentProvider not set in InvoiceProvider.");
      return;
    }

    final payments = await _paymentRepository.getPaymentsByInvoiceId(invoiceId);
    double totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

    final linkedTreatments =
        await _invoiceTreatmentRepository.getInvoiceTreatmentsByInvoiceId(invoiceId);

    double remainingPaid = totalPaid;

    for (final lt in linkedTreatments) {
      final treatment = await _treatmentProvider.getTreatmentById(lt.treatmentId);
      if (treatment != null && treatment.agreedAmount != null) {
        final amountToApply = min(remainingPaid, treatment.agreedAmount!);
        await _treatmentProvider.updateTreatmentPaidAmount(
            treatment.treatmentId!, amountToApply);
        remainingPaid -= amountToApply;
      } else {
        await _treatmentProvider.updateTreatmentPaidAmount(lt.treatmentId, 0.0);
      }
    }

    await _updateInvoiceStatus(invoiceId);
  }

  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    return await _paymentRepository.getPaymentsByInvoiceId(invoiceId);
  }

  Future<Invoice?> findLatestOpenInvoice(int patientId) async {
    await fetchInvoices();
    final patientInvoices =
        _invoices.where((inv) => inv.patientId == patientId).toList();

    final openInvoices =
        patientInvoices.where((inv) => inv.status != 'مدفوعة بالكامل').toList();
    if (openInvoices.isNotEmpty) {
      openInvoices.sort((a, b) =>
          DateTime.parse(b.invoiceDate).compareTo(DateTime.parse(a.invoiceDate)));
      return openInvoices.first;
    }
    return null;
  }

  Future<void> addTreatmentToInvoice(
      {required int patientId, required int treatmentId, int? invoiceId}) async {
    Invoice? targetInvoice;
    if (invoiceId != null) {
      targetInvoice = await _invoiceRepository.getInvoiceById(invoiceId);
    } else {
      targetInvoice = await findLatestOpenInvoice(patientId);
    }

    if (targetInvoice != null) {
      final existingTreatments = await _invoiceTreatmentRepository
          .getInvoiceTreatmentsByInvoiceId(targetInvoice.invoiceId!);
      final existingTreatmentIds =
          existingTreatments.map((it) => it.treatmentId).toList();
      if (!existingTreatmentIds.contains(treatmentId)) {
        await updateInvoice(targetInvoice, [...existingTreatmentIds, treatmentId]);
      }
    } else {
      final newInvoice = Invoice(
        patientId: patientId,
        invoiceDate: DateTime.now().toIso8601String(),
        status: 'مسودة',
      );
      await addInvoice(newInvoice, [treatmentId]);
    }
  }
}
