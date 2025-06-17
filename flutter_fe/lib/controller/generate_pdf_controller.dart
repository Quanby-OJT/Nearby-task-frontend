import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List> generatePdf() async {
  final pdf = pw.Document();

  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/app_icon.png')).buffer.asUint8List(),
  );

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: [
              pw.Image(logo, width: 50, height: 50),
              pw.SizedBox(width: 10),
              pw.Text('Your Task Details',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('Title: Moving Items'),
            pw.SizedBox(height: 10),
            pw.Text(
                'Description: Hi. I got a new job that requires on-site work in Cebu. So I decide to purchase a new condo in Downtown Cebu City. However, this requires moving items such as appliances, furniture and equipment since my new condo is furnished. So I need movers that can move items. I need someone that knows what I need. I will explain further once you applied for this job.'),
            pw.SizedBox(height: 10),
            pw.Text('Date: June 30, 2025'),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
