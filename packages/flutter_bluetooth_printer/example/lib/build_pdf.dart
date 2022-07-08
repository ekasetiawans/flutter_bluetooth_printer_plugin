import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildPdf() async {
  final pdf = pw.Document();

  const format = PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 1 * PdfPageFormat.mm,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: format,
      theme: pw.ThemeData(
        defaultTextStyle: const pw.TextStyle(
          fontSize: 11,
        ),
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Column(
              children: [
                pw.FittedBox(
                  child: pw.Text(
                    'HELLO WORLD',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4.0),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.fromType(pw.BarcodeType.QrCode),
                  data: 'https://maseka.dev',
                  width: 80,
                  height: 80,
                ),
              ],
            ),
            pw.SizedBox(height: 8.0),
            pw.FittedBox(
              child: pw.Text(
                'PURCHASE RECEIPT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            pw.Text(
              DateTime.now().toIso8601String(),
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
            pw.SizedBox(height: 8.0),
            pw.Divider(
              height: 8.0,
              borderStyle: pw.BorderStyle.dotted,
              color: PdfColors.black,
              thickness: 1.0,
            ),
            pw.Divider(
              height: 8.0,
              borderStyle: pw.BorderStyle.dotted,
              color: PdfColors.black,
              thickness: 1.0,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'THANK YOU',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 24),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
