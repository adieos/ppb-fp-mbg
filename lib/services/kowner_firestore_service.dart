import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import './admin_firestore_service.dart';

class KownerFirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference reports = FirebaseFirestore.instance.collection(
    'reports',
  );

  User? get currentUser => _auth.currentUser;

  /*
  X  required this.id, // auto generated
  X  required this.kitchenId, // delete? sama kek id
  X  required this.kitchenName, // delete? sama kek ownerUid
  X  required this.ownerUid, //get from auth
    required this.date, 
    required this.menuItems,
    required this.totalBeneficiaries,
    required this.distributionTime,
    required this.proofImageUrls,
  X  required this.status, // default dl: pending
  X  this.rejectionReason, // ga diisi user
  X  this.verifiedBy, // ga diisi user
  X  this.verifiedAt, // ga diisi user
  X  required this.isHoliday, // default: false
  X  required this.createdAt, // get from Timestamp.now() 
  X required this.updatedAt,
    */

  Future<void> createReport(
    DateTime date,
    List<MenuItemModel> menu,
    int totalBeneficiaries,
    String distributionTime,
    List<String> proofImageUrls,
  ) async {
    final AdminFirestoreService usergetter = AdminFirestoreService();
    final theuser = await usergetter.getUser(currentUser!.uid);
    await reports.add({
      'kitchenId': 'GA KEPAKE (harusny sm kek ownerUid)',
      'kitchenName': theuser?.name ?? 'Unknown dapur le',
      'status': ReportStatus.draft,
      'rejectionReason': null,
      'verifiedBy': null,
      'verifiedAt': null,
      'isHoliday': false,
      'createdAt': Timestamp.now(),
      'updatedAt': null,
      'ownerUid': currentUser!.uid,
      'date': Timestamp.fromDate(date),
      'menuItems': menu.map((m) => m.toMap()).toList(),
      'totalBeneficiaries': totalBeneficiaries,
      'distributionTime': distributionTime,
      'proofImageUrls': proofImageUrls,
    });
  }

  // get reports of a kitcher
  Stream<List<ReportModel>> getReports() {
    return reports.where('ownerUid', isEqualTo: currentUser!.uid).snapshots()
    // this returns Stream<QuerySnapshot>
    .map((s) {
      // s represents QuerySnapshot and will be transformed into List<ReportModel>
      final list = s.docs
          .map(ReportModel.fromFirestore)
          .toList(); // map() returns lazy iterable so a list essentially idk. the other map() does the same thing
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // gaperlu getReportDetail(). func di atas suda return all detail report, jd tar page detail report bakal nerima full ReportModel object ny

  Future<void> updateReport(
    String docID,
    DateTime date,
    List<MenuItemModel> menu,
    int totalBeneficiaries,
    String distributionTime,
    List<String> proofImageUrls,
  ) {
    return reports.doc(docID).update({
      'status': ReportStatus.draft, // prevent cheating
      'updatedAt': Timestamp.now(),
      'date': Timestamp.fromDate(date),
      'menuItems': menu.map((m) => m.toMap()).toList(),
      'totalBeneficiaries': totalBeneficiaries,
      'distributionTime': distributionTime,
      'proofImageUrls': proofImageUrls,
    });
  }

  Future<void> deleteReport(String id) {
    return reports.doc(id).delete();
  }

  // flow: login -> AuthGate() -> kowner_shell (di dalemnya ada screens[])
  // di navbar:  list reports, create report, pending reports (bsia jd calendars or smth), profile. 4 bagian kek di admin
}
