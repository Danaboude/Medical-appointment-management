import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models/laboratory_item.dart';

class PdfLaboratoryService {
  static Future<Uint8List> generateLaboratoryPdf(
    List<LaboratoryItem> items,
    AppLocalizations appLocalizations,
  ) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final boldFont = pw.Font.ttf(boldFontData);

    final ByteData image = await rootBundle.load('assets/appicon.png');
    Uint8List imageData = (image).buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(appLocalizations.laboratory, style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.black)),
              pw.Image(pw.MemoryImage(imageData), width: 90, height: 90),
            ],
          ),
          pw.SizedBox(height: 30),
          _buildTreatmentsTable(items, appLocalizations, font, boldFont),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTreatmentsTable(
      List<LaboratoryItem> items,
      AppLocalizations appLocalizations,
      pw.Font font,
      pw.Font boldFont) {
    return pw.Table.fromTextArray(
      headers: [
        appLocalizations.patientId,
        appLocalizations.patientName,
        appLocalizations.toothNumber,
        appLocalizations.notesFormField,
      ],
      data: items.map((item) {
        return [
          item.patient.patientId.toString(),
          item.patient.name,
          item.treatment.toothNumber ?? '',
          item.note,
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.black),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
      cellStyle: pw.TextStyle(font: font),
      cellAlignment: pw.Alignment.center,
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(3),
      },
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  static Future<String> savePdf(String name, Uint8List bytes) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory laboratorysDir = Directory('${appDocDir.path}/laboratorys');
    if (!await laboratorysDir.exists()) {
      await laboratorysDir.create(recursive: true);
    }

    final File file = File('${laboratorysDir.path}/$name.pdf');
    await file.writeAsBytes(bytes);

    if (Platform.isWindows) {
      final String normalizedPath = file.path.replaceAll('/', '\\');
      await Process.run(
        'explorer',
        ['/select,', normalizedPath],
        runInShell: true,
      );
    } else if (Platform.isMacOS) {
      await Process.run("open", ["-R", file.path]);
    } else if (Platform.isLinux) {
      final folder = file.parent.path;
      await Process.run("xdg-open", [folder]);
    }

    return file.path;
  }
}