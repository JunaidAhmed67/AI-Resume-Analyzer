import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import 'improved_resume_screen.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisResult result;
  final String? resumeText; // needed to create the improved resume
  const ResultScreen({super.key, required this.result, this.resumeText});

  Color _scoreColor(int s) =>
      s >= 75 ? Colors.green : (s >= 50 ? Colors.orange : Colors.red);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              height: 130,
              width: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 130,
                    width: 130,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 10,
                      color: _scoreColor(result.score),
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${result.score}',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Text('/ 100'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (result.targetRole.isNotEmpty)
            Center(child: Text('Target role: ${result.targetRole}')),
          Center(
              child: Text('Source: ${result.source}',
                  style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 16),
          Text(result.summary),
          _section(context, 'Strengths', Icons.thumb_up_alt_outlined,
              result.strengths),
          _chips(context, 'Skills found', result.detectedSkills,
              Colors.green.shade100),
          _chips(context, 'Missing skills', result.missingSkills,
              Colors.red.shade100),
          _section(context, 'Suggested improvements',
              Icons.lightbulb_outline, result.improvements),
          if (resumeText != null && resumeText!.trim().length >= 50) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImprovedResumeScreen(
                    resumeText: resumeText!,
                    targetRole: result.targetRole,
                    analysis: result,
                  ),
                ),
              ),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Create improved resume (PDF)'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _title(BuildContext context, String t, [IconData? icon]) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(t,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _section(
      BuildContext context, String title, IconData icon, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, title, icon),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(i)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chips(
      BuildContext context, String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, title),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final i in items)
              Chip(
                label: Text(i, style: const TextStyle(color: Colors.black87)),
                backgroundColor: color,
              ),
          ],
        ),
      ],
    );
  }
}
