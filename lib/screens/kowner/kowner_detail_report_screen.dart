import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/admin_firestore_service.dart';
import '../../services/minio_service.dart';

class KownerDetailReportScreen extends StatefulWidget {
  final ReportModel report;
  const KownerDetailReportScreen({super.key, required this.report});

  @override
  State<KownerDetailReportScreen> createState() => _KDRState();
}

class _KDRState extends State<KownerDetailReportScreen> {
  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.kitchenName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy').format(report.date),
              style: const TextStyle(color: Color(0xFF8A8FA8)),
            ),
            const SizedBox(height: 16),

            Text(
              'Status: ${report.status}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Total Penerima: ${report.totalBeneficiaries}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Waktu Distribusi: ${report.distributionTime}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Hari Libur: ${report.isHoliday ? 'Ya' : 'Tidak'}',
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 16),
            const Text(
              'Menu:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...report.menuItems.map(
              (item) => Text(
                '- ${item.name}: ${item.portionCount} porsi',
                style: const TextStyle(color: Color(0xFF8A8FA8)),
              ),
            ),

            if (report.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Text(
                'Alasan Penolakan: ${report.rejectionReason}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
