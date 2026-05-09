import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  Future<void> exportCsv({
    required String fileName,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> exportSimplePdf({
    required String fileName,
    required String title,
    required Map<String, String> entries,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text(title)),
          ...entries.entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[pw.Text(entry.key), pw.Text(entry.value)],
              ),
            ),
          ),
        ],
      ),
    );
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<void> printSimplePdf({
    required String fileName,
    required String title,
    required Map<String, String> entries,
  }) async {
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => <pw.Widget>[
              pw.Header(level: 0, child: pw.Text(title)),
              ...entries.entries.map(
                (entry) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(entry.key),
                      pw.Text(entry.value),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        return pdf.save();
      },
    );
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
