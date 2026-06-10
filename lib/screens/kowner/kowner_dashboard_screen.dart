import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:monitorbg/models/report_model.dart';
import 'package:monitorbg/screens/kowner/kowner_detail_report_screen.dart';
import '../../services/kowner_firestore_service.dart';

class KownerDashboardScreen extends StatefulWidget {
  const KownerDashboardScreen({super.key});

  @override
  State<KownerDashboardScreen> createState() => _KDState();
}

class _KDState extends State<KownerDashboardScreen> {
  final _svc = KownerFirestoreService();
  @override
  Widget build(BuildContext build) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text('Daftar Laporan'),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _svc.getReports(),
        builder: (context, snap) {
          // TO DO: ISI INI
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final reports = snap.data ?? [];
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: Color(0xFF8A8FA8),
                    size: 52,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan',
                    style: TextStyle(color: Color(0xFF8A8FA8)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _ReportCard(report: reports[i]),
          );
        },
      ),
    );
  }
}

// ambil dari punya admin awokawokaoka

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KownerDetailReportScreen(report: report),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: report.isHoliday
              ? Colors.red.withValues(alpha: 0.15)
              : Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: report.isHoliday
                ? Colors.red.withValues(alpha: 0.4)
                : Color(0xFF2A2D3E),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMM yyyy').format(report.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    '${report.totalBeneficiaries} penerima · ${report.distributionTime}',
                    style: const TextStyle(
                      color: Color(0xFF8A8FA8),
                      fontSize: 13,
                    ),
                  ),
                  if (report.isHoliday) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Hari Libur!',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            _StatusBadge(status: report.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          color: config['fg'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case ReportStatus.verified:
        return {
          'label': 'Verified',
          'bg': Colors.green.withOpacity(0.15),
          'fg': Colors.greenAccent,
        };
      case ReportStatus.rejected:
        return {
          'label': 'Rejected',
          'bg': Colors.red.withOpacity(0.15),
          'fg': Colors.redAccent,
        };
      case ReportStatus.submitted:
        return {
          'label': 'Pending',
          'bg': Colors.orange.withOpacity(0.15),
          'fg': Colors.orange,
        };
      default:
        return {
          'label': 'Draft',
          'bg': Colors.grey.withOpacity(0.15),
          'fg': Colors.grey,
        };
    }
  }
}
