import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:monitorbg/models/report_model.dart';
import 'package:monitorbg/screens/kowner/kowner_detail_report_screen.dart';
import '../../services/kowner_firestore_service.dart';
import '../../services/holiday.dart';

class KownerThirdScreen extends StatefulWidget {
  const KownerThirdScreen({super.key});

  @override
  State<KownerThirdScreen> createState() => _KTSState();
}

class _KTSState extends State<KownerThirdScreen> {
  final _svc = KownerFirestoreService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text('buat tes dl'),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _svc.getReports(),
        builder: (context, snap) {
          final reports = snap.data ?? [];
          if (reports.isEmpty) {
            return Text("kosong");
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),

            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _IsHoliday(report: reports[index]),
          );
        },
      ),
    );
  }
}

class _IsHoliday extends StatelessWidget {
  final ReportModel report;
  const _IsHoliday({required this.report});
  static final _hday = HolidayService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _hday.checkIsHoliday(report.date),
      builder: (ctx, snap) {
        if (snap.data == true) {
          return Text("libur woy");
        }

        return Text("hai");
      },
    );
  }
}
