import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_treatment.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../models/treatment.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf(
    Invoice invoice,
    Patient patient,
    List<InvoiceTreatment> invoiceTreatments,
    List<Treatment> allTreatments,
    List<Payment> payments,
    AppLocalizations appLocalizations,
  ) async {
    print('PDF generation started.');
    try {
      final pdf = pw.Document();

      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final font = pw.Font.ttf(fontData);

      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      final boldFont = pw.Font.ttf(boldFontData);
      print('Fonts loaded.');

      final ByteData image = await rootBundle.load('assets/appicon.png');
      Uint8List imageData = (image).buffer.asUint8List();
      print('Image loaded.');

      print('Starting amount calculations.');
      print('Starting amount calculations.');
      final paidAmount = payments.fold(0.0, (sum, p) => sum + p.amount);
      final totalAmount = invoice.totalAmount ?? 0.0;
      final remainingAmount = totalAmount - paidAmount;

      final formattedTotal = NumberFormat.currency(
              locale: appLocalizations.localeName,
              symbol: appLocalizations.currencySymbol)
          .format(totalAmount);
      final formattedPaid = NumberFormat.currency(
              locale: appLocalizations.localeName,
              symbol: appLocalizations.currencySymbol)
          .format(paidAmount);
      final formattedRemaining = NumberFormat.currency(
              locale: appLocalizations.localeName,
              symbol: appLocalizations.currencySymbol)
          .format(remainingAmount);
      print('Amounts calculated.');

      print('Adding PDF page.');
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) => [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(appLocalizations.invoice,
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 24,
                            color: PdfColors.black)),
                    pw.Text(
                        '${appLocalizations.invoiceNumber}: #${invoice.invoiceId}',
                        style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.Text(
                        '${appLocalizations.date}: ${DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(invoice.invoiceDate))}',
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
                pw.Image(pw.MemoryImage(imageData), width: 90, height: 90),
              ],
            ),
            pw.SizedBox(height: 30),

            // Patient Information
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(appLocalizations.patientInformation,
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.black)),
                  pw.Divider(color: PdfColors.black),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${appLocalizations.patientName}:',
                          style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text(patient.name,
                          style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${appLocalizations.phoneNumber}:',
                          style: pw.TextStyle(font: font, fontSize: 12)),
                      pw.Text(patient.phone ?? appLocalizations.notAvailable,
                          style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Treatments Table
            pw.Text(appLocalizations.treatments,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 16, color: PdfColors.black)),
            pw.SizedBox(height: 10),
            _buildTreatmentsTable(invoiceTreatments, allTreatments,
                appLocalizations, font, boldFont),
            pw.SizedBox(height: 20),

            // Payments Table
            pw.Text(appLocalizations.payments,
                style: pw.TextStyle(
                    font: boldFont, fontSize: 16, color: PdfColors.black)),
            pw.SizedBox(height: 10),
            _buildPaymentsTable(payments, appLocalizations, font, boldFont),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildSummaryRow(appLocalizations.totalAmount, formattedTotal,
                      font, boldFont),
                  pw.SizedBox(height: 5),
                  _buildSummaryRow(appLocalizations.paidAmount, formattedPaid,
                      font, boldFont),
                  pw.Divider(color: PdfColors.black),
                  _buildSummaryRow(appLocalizations.remainingAmount, remainingAmount.toString(),
                      font, boldFont),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Footer
            pw.Center(
              child: pw.Text(appLocalizations.thankYouMessage,
                  style: pw.TextStyle(
                      font: font, fontSize: 10, color: PdfColors.grey)),
            ),
          ],
        ),
      );

      print('PDF saved successfully.');
      return pdf.save();
    } catch (e) {
      print('Error during PDF generation: $e');
      rethrow; // Re-throw the error so it's still visible
    }
  }

  static pw.Widget _buildTreatmentsTable(
      List<InvoiceTreatment> invoiceTreatments,
      List<Treatment> allTreatments,
      AppLocalizations appLocalizations,
      pw.Font font,
      pw.Font boldFont) {
    final linkedTreatments = allTreatments.where((treatment) {
      return invoiceTreatments
          .any((it) => it.treatmentId == treatment.treatmentId);
    }).toList();

    return pw.Table.fromTextArray(
      headers: [
        appLocalizations.treatment,
        appLocalizations.agreedAmount,
      ],
      data: linkedTreatments.map((treatment) {
        final formattedAmount = NumberFormat.currency(
          locale: appLocalizations.localeName,
          symbol: appLocalizations.currencySymbol,
        ).format(treatment.agreedAmount ?? 0);
        return [
          treatment.diagnosis ?? appLocalizations.noDiagnosis,
          formattedAmount,
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.black),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
      cellStyle: pw.TextStyle(font: font),
      cellAlignment: pw.Alignment.center,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
      },
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  static pw.Widget _buildPaymentsTable(List<Payment> payments,
      AppLocalizations appLocalizations, pw.Font font, pw.Font boldFont) {
    return pw.Table.fromTextArray(
      headers: [
        appLocalizations.date,
        appLocalizations.method,
        appLocalizations.amount,
      ],
      data: payments.map((payment) {
        final formattedAmount = NumberFormat.currency(
          locale: appLocalizations.localeName,
          symbol: appLocalizations.currencySymbol,
        ).format(payment.amount);
        return [
          DateFormat.yMd(appLocalizations.localeName)
              .format(DateTime.parse(payment.paymentDate)),
          payment.method,
          formattedAmount,
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.black),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
      cellStyle: pw.TextStyle(font: font),
      cellAlignment: pw.Alignment.center,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  static pw.Widget _buildSummaryRow(
      String label, String value, pw.Font font, pw.Font boldFont,
      {bool isHighlight = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12)),
        pw.Text(value,
            style: isHighlight
                ? pw.TextStyle(
                    font: boldFont, fontSize: 14, color: PdfColors.black)
                : pw.TextStyle(font: boldFont, fontSize: 12)),
      ],
    );
  }

  static Future<String> savePdf(String name, Uint8List bytes) async {
    // Get app's document directory (persistent, not temporary)
    final Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create "invoices" folder if it doesn't exist
    final Directory invoicesDir = Directory('${appDocDir.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    // Define file path inside invoices folder
    final File file = File('${invoicesDir.path}/$name.pdf');

    // Write the file
    await file.writeAsBytes(bytes);
    // Open folder & highlight file depending on platform
    // Open folder & highlight file depending on platform
    if (Platform.isWindows) {
      // Opens File Explorer and selects the file
      final String normalizedPath = file.path.replaceAll('/', '\\');
      await Process.run(
        'explorer',
        ['/select,', normalizedPath],
        runInShell: true,
      );
    } else if (Platform.isMacOS) {
      // On macOS, reveal in Finder
      await Process.run("open", ["-R", file.path]);
    } else if (Platform.isLinux) {
      // On Linux, open the containing folder
      final folder = file.parent.path;
      await Process.run("xdg-open", [folder]);
    }

    print("PDF saved at: ${file.path}");
    return file.path;
  }
}
