import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User ────────────────────────────────────────────────

  /// Fetch the current user's role from Firestore.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ─── Reports ─────────────────────────────────────────────

  Stream<List<ReportModel>> getAllReports() {
    return _db
        .collection('reports')
        .where('status', whereIn: ['submitted', 'verified', 'rejected'])
        .snapshots()
        .map((s) {
          final list = s.docs.map(ReportModel.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// Stream of reports filtered by status.
  Stream<List<ReportModel>> getReportsByStatus(String status) {
    return _db
        .collection('reports')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) {
          final list = s.docs.map(ReportModel.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// Verify a report — sets status to 'verified'.
  Future<void> verifyReport(String reportId, String adminUid) async {
    await _db.collection('reports').doc(reportId).update({
      'status': ReportStatus.verified,
      'verifiedBy': adminUid,
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a report — sets status to 'rejected' with reason.
  Future<void> rejectReport(
      String reportId, String reason, String adminUid) async {
    await _db.collection('reports').doc(reportId).update({
      'status': ReportStatus.rejected,
      'rejectionReason': reason,
      'verifiedBy': adminUid,
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Dashboard Stats ─────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final snap = await _db.collection('reports').get();
    final reports = snap.docs
        .map(ReportModel.fromFirestore)
        .where((r) => r.status != 'draft')
        .toList();
    return {
      'total': reports.length,
      'submitted': reports.where((r) => r.status == 'submitted').length,
      'verified': reports.where((r) => r.status == 'verified').length,
      'rejected': reports.where((r) => r.status == 'rejected').length,
    };
  }

  // ─── FCM token helpers ───────────────────────────────────

  /// Get FCM tokens of all kitchen owners who haven't submitted today.
  Future<List<String>> getPendingOwnerTokens() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // All kitchen owner uids who submitted today
    final submittedSnap = await _db
        .collection('reports')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .where('status', whereIn: [
          ReportStatus.submitted,
          ReportStatus.verified
        ])
        .get();

    final submittedUids =
        submittedSnap.docs.map((d) => d['ownerUid'] as String).toSet();

    // All kitchen owner tokens
    final ownersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'kitchen_owner')
        .get();

    return ownersSnap.docs
        .where((d) => !submittedUids.contains(d.id))
        .map((d) => d['fcmToken'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
