import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/firestore_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Past Analyses')),
      body: StreamBuilder(
        stream: service.history(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No analyses yet.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final result = AnalysisResult.fromJson(data);
              final ts = data['createdAt'];
              final date = ts != null
                  ? ts.toDate().toString().substring(0, 16)
                  : 'just now';
              return ListTile(
                leading: CircleAvatar(child: Text('${result.score}')),
                title: Text(data['fileName']?.toString() ?? 'Resume'),
                subtitle: Text(
                    '${result.targetRole.isEmpty ? 'General' : result.targetRole}  •  $date'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => service.delete(uid, doc.id),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ResultScreen(
                          result: result,
                          resumeText: data['resumeText']?.toString())),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
