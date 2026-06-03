import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/admin_firestore_service.dart';
import '../../services/minio_service.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  const AdminReportDetailScreen({super.key, required this.report});

  @override
  State<AdminReportDetailScreen> createState() => _State();
}

class _State extends State<AdminReportDetailScreen> {
  final _service = AdminFirestoreService();
  bool _loading = false;

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await _service.verifyReport(
        widget.report.id,
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan diverifikasi'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tulis alasan...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.rejectReport(
        widget.report.id,
        reason,
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan ditolak'), backgroundColor: Colors.orange),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final canAct = r.status == 'submitted';

    return Scaffold(
      appBar: AppBar(title: Text(r.kitchenName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            if (r.status != 'submitted')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                color: r.status == 'verified'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Text(
                  r.status == 'verified'
                      ? 'Terverifikasi'
                      : 'Ditolak: ${r.rejectionReason ?? '-'}',
                  style: TextStyle(
                    color: r.status == 'verified' ? Colors.green : Colors.red,
                  ),
                ),
              ),

            // Info
            Text('Tanggal: ${DateFormat('d MMMM yyyy').format(r.date)}'),
            Text('Jam Distribusi: ${r.distributionTime}'),
            Text('Total Penerima: ${r.totalBeneficiaries} orang'),
            const Divider(height: 24),

            // Menu
            const Text('Menu:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...r.menuItems.map((m) => Text('• ${m.name} — ${m.portionCount} porsi')),
            const Divider(height: 24),

            // Photos
            if (r.proofImageUrls.isNotEmpty) ...[
              const Text('Foto Bukti:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _ProofImages(objectPaths: r.proofImageUrls),
            ],

            const SizedBox(height: 32),

            // Actions
            if (canAct)
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _verify,
                            child: const Text('Verifikasi'),
                          ),
                        ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }
}

/// Loads each proof image via MinIO presigned URL then displays it.
class _ProofImages extends StatelessWidget {
  final List<String> objectPaths;
  const _ProofImages({required this.objectPaths});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: objectPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => FutureBuilder<String>(
          future: MinioService().getPresignedUrl(objectPaths[i]),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 100, height: 100,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return const SizedBox(
                width: 100, height: 100,
                child: Icon(Icons.broken_image),
              );
            }
            return Image.network(
              snap.data!,
              width: 100, height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }
}
