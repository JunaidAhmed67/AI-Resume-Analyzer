import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/analysis_result.dart';
import '../models/improved_resume.dart';
import '../services/pdf_builder.dart';
import '../services/resume_writer_service.dart';

class ImprovedResumeScreen extends StatefulWidget {
  final String resumeText;
  final String targetRole;
  final AnalysisResult analysis;

  const ImprovedResumeScreen({
    super.key,
    required this.resumeText,
    required this.targetRole,
    required this.analysis,
  });

  @override
  State<ImprovedResumeScreen> createState() => _ImprovedResumeScreenState();
}

class _ImprovedResumeScreenState extends State<ImprovedResumeScreen> {
  late Future<ImprovedResume> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ImprovedResume> _load() => ResumeWriterService().improve(
        resumeText: widget.resumeText,
        targetRole: widget.targetRole,
        analysis: widget.analysis,
      );

  String _fileName(ImprovedResume r) {
    final base = r.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return '${base.isEmpty ? 'Improved' : base}_Resume.pdf';
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// Opens the system print/save dialog: choose "Save as PDF" to download.
  Future<void> _download(ImprovedResume r) async {
    try {
      final bytes = await PdfBuilder().build(r);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _fileName(r),
      );
    } catch (e) {
      _msg('Could not create the PDF: $e');
    }
  }

  Future<void> _share(ImprovedResume r) async {
    try {
      final bytes = await PdfBuilder().build(r);
      await Printing.sharePdf(bytes: bytes, filename: _fileName(r));
    } catch (e) {
      _msg('Could not share the PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Improved Resume')),
      body: FutureBuilder<ImprovedResume>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Writing your improved resume...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            var err = snapshot.error.toString().replaceFirst('Exception: ', '');
            if (err.length > 220) err = '${err.substring(0, 220)}...';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(err, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final r = snapshot.data!;
          return Column(
            children: [
              Expanded(child: _preview(context, r)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _download(r),
                          icon: const Icon(Icons.download),
                          label: const Text('Download PDF'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Share',
                        onPressed: () => _share(r),
                        icon: const Icon(Icons.share),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Copy text',
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: r.toPlainText()));
                          _msg('Resume text copied.');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _preview(BuildContext context, ImprovedResume r) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Widget head(String s) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(s.toUpperCase(),
              style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.primary)),
        );
    Widget bullet(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('\u2022  '),
              Expanded(child: Text(s)),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'This is an AI-written draft based only on your CV. '
            'Check every detail and add real numbers where you can before sending it.',
          ),
        ),
        const SizedBox(height: 16),
        Text(r.name,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        if (r.headline.isNotEmpty) Text(r.headline),
        if (r.contact.isNotEmpty) Text(r.contact, style: t.bodySmall),
        if (r.summary.isNotEmpty) ...[head('Summary'), Text(r.summary)],
        if (r.skills.isNotEmpty) ...[
          head('Skills'),
          for (final s in r.skills) Padding(
              padding: const EdgeInsets.only(bottom: 3), child: Text(s)),
        ],
        if (r.experience.isNotEmpty) ...[
          head('Experience'),
          for (final e in r.experience) ...[
            Text(
              e.organization.isEmpty
                  ? e.title
                  : '${e.title} - ${e.organization}',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (e.dates.isNotEmpty) Text(e.dates, style: t.bodySmall),
            const SizedBox(height: 4),
            for (final b in e.bullets) bullet(b),
            const SizedBox(height: 8),
          ],
        ],
        if (r.projects.isNotEmpty) ...[
          head('Projects'),
          for (final p in r.projects) ...[
            Text(p.name,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final b in p.bullets) bullet(b),
            const SizedBox(height: 8),
          ],
        ],
        if (r.education.isNotEmpty) ...[
          head('Education'),
          for (final e in r.education) Padding(
              padding: const EdgeInsets.only(bottom: 3), child: Text(e)),
        ],
        if (r.certifications.isNotEmpty) ...[
          head('Certifications'),
          for (final c in r.certifications) bullet(c),
        ],
      ],
    );
  }
}
