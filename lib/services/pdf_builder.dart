import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/improved_resume.dart';

class PdfBuilder {
  static const PdfColor _navy = PdfColor.fromInt(0xFF1F3864);
  static const PdfColor _grey = PdfColor.fromInt(0xFF555555);

  Future<Uint8List> build(ImprovedResume r) async {
    final doc = pw.Document(title: '${r.name} - Resume', author: r.name);

    final body = pw.TextStyle(fontSize: 10, lineSpacing: 2);
    final bold = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);

    pw.Widget heading(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(t.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 2),
              pw.Container(height: 0.8, color: _navy),
            ],
          ),
        );

    pw.Widget bullet(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
          child: pw.Bullet(text: t, style: body, bulletSize: 3),
        );

    final widgets = <pw.Widget>[
      pw.Text(r.name,
          style: pw.TextStyle(
              fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy)),
      if (r.headline.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Text(r.headline,
              style: const pw.TextStyle(fontSize: 11.5, color: _grey)),
        ),
      if (r.contact.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Text(r.contact,
              style: const pw.TextStyle(fontSize: 9.5, color: _grey)),
        ),
      if (r.summary.isNotEmpty) ...[
        heading('Summary'),
        pw.Text(r.summary, style: body, textAlign: pw.TextAlign.justify),
      ],
      if (r.skills.isNotEmpty) ...[
        heading('Skills'),
        for (final s in r.skills)
          pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(s, style: body)),
      ],
      if (r.experience.isNotEmpty) ...[
        heading('Experience'),
        for (final e in r.experience) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  e.organization.isEmpty
                      ? e.title
                      : '${e.title} - ${e.organization}',
                  style: bold,
                ),
              ),
              if (e.dates.isNotEmpty)
                pw.Text(e.dates,
                    style: const pw.TextStyle(fontSize: 9.5, color: _grey)),
            ],
          ),
          pw.SizedBox(height: 2),
          for (final b in e.bullets) bullet(b),
        ],
      ],
      if (r.projects.isNotEmpty) ...[
        heading('Projects'),
        for (final p in r.projects) ...[
          pw.SizedBox(height: 4),
          pw.Text(p.name, style: bold),
          pw.SizedBox(height: 2),
          for (final b in p.bullets) bullet(b),
        ],
      ],
      if (r.education.isNotEmpty) ...[
        heading('Education'),
        for (final e in r.education)
          pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(e, style: body)),
      ],
      if (r.certifications.isNotEmpty) ...[
        heading('Certifications'),
        for (final c in r.certifications) bullet(c),
      ],
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) => widgets,
      ),
    );
    return doc.save();
  }
}
