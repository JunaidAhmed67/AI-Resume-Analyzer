import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analysis_result.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('analyses');

  Future<void> save(String uid,
      {required String fileName, required AnalysisResult result}) {
    return _col(uid).add({
      ...result.toJson(),
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> history(String uid) =>
      _col(uid).orderBy('createdAt', descending: true).snapshots();

  Future<void> delete(String uid, String docId) =>
      _col(uid).doc(docId).delete();
}
