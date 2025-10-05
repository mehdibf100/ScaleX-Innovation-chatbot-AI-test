import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> exportChatAsPdf(String title, List<Map<String,String>> messages) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text(title)),
        pw.SizedBox(height: 10),
        pw.ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final m = messages[index];
            return pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${m['role']}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(m['content'] ?? '')
                ],
              ),
            );
          },
        )
      ],
    ),
  );
  // show share/print dialog
  await Printing.sharePdf(bytes: await doc.save(), filename: '$title.pdf');
}
