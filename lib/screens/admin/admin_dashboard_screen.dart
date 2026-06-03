import 'package:flutter/material.dart';
import '../../services/admin_firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _State();
}

class _State extends State<AdminDashboardScreen> {
  final _service = AdminFirestoreService();
  Map<String, int>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await _service.getDashboardStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatTile('Total Laporan',       _stats?['total'] ?? 0,     Icons.assignment,      Colors.blue),
                  _StatTile('Menunggu Verifikasi',  _stats?['submitted'] ?? 0, Icons.pending_actions, Colors.orange),
                  _StatTile('Terverifikasi',        _stats?['verified'] ?? 0,  Icons.check_circle,    Colors.green),
                  _StatTile('Ditolak',              _stats?['rejected'] ?? 0,  Icons.cancel,          Colors.red),
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label),
        trailing: Text(
          '$value',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
