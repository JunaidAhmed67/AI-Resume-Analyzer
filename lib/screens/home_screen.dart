import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  String? _fileName;
  bool _loading = false;

  @override
  void dispose() {
    _roleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickPdf() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty) return; // user cancelled
      final file = files.first;
      final bytes = await file.readAsBytes();
      final text = PdfService().extractText(bytes);
      if (text.trim().length < 50) {
        _msg('Could not read text from this PDF (it may be a scanned image). '
            'Paste the text manually instead.');
        return;
      }
      setState(() {
        _fileName = file.name;
        _textCtrl.text = text;
      });
    } catch (e) {
      _msg('Failed to read PDF: $e');
    }
  }

  Future<void> _analyze() async {
    final text = _textCtrl.text.trim();
    if (text.length < 50) {
      _msg('Upload a PDF or paste your resume text first.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AiService()
          .analyze(resumeText: text, targetRole: _roleCtrl.text.trim());

      // Save to Firebase, but do not block the result if saving fails.
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirestoreService()
            .save(uid,
                fileName: _fileName ?? 'Pasted text',
                result: result,
                resumeText: text);
      } catch (e) {
        _msg('Result shown, but saving to Firebase failed: $e');
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResultScreen(result: result, resumeText: text)),
      );
    } catch (e) {
      _msg('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Analyzer'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Signed in as ${FirebaseAuth.instance.currentUser?.email ?? ''}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _roleCtrl,
            decoration: const InputDecoration(
              labelText: 'Target job role (optional)',
              hintText: 'e.g. Flutter Developer, Data Analyst',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName == null
                ? 'Upload resume (PDF)'
                : 'Selected: $_fileName'),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('or paste your resume text')),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: 'Resume text appears here after uploading a PDF...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _analyze,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Analyzing...' : 'Analyze Resume'),
          ),
        ],
      ),
    );
  }
}
