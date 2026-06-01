import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/admin_firestore_service.dart';
import 'admin_report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  /// Pass null to show all reports, or a [ReportStatus] string to filter.
  final String? filterStatus;

  const AdminReportsScreen({super.key, required this.filterStatus});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _service = AdminFirestoreService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final stream = widget.filterStatus == null
        ? _service.getAllReports()
        : _service.getReportsByStatus(widget.filterStatus!);

    final title = widget.filterStatus == null
        ? 'Semua Laporan'
        : 'Menunggu Verifikasi';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama dapur...',
                hintStyle: const TextStyle(color: Color(0xFF8A8FA8)),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF8A8FA8), size: 20),
                filled: true,
                fillColor: const Color(0xFF0F1117),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style:
                        const TextStyle(color: Colors.redAccent)));
          }

          var reports = snap.data ?? [];
          if (_search.isNotEmpty) {
            reports = reports
                .where((r) =>
                    r.kitchenName.toLowerCase().contains(_search))
                .toList();
          }

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      color: Color(0xFF8A8FA8), size: 52),
                  SizedBox(height: 12),
                  Text('Belum ada laporan',
                      style: TextStyle(color: Color(0xFF8A8FA8))),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _ReportCard(report: reports[i]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminReportDetailScreen(report: report),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2D3E)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.kitchenName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(report.date),
                    style: const TextStyle(
                        color: Color(0xFF8A8FA8), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.totalBeneficiaries} penerima · ${report.distributionTime}',
                    style: const TextStyle(
                        color: Color(0xFF8A8FA8), fontSize: 13),
                  ),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
