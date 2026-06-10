import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/kowner_firestore_service.dart';
import '../../services/minio_service.dart';

class KownerCreateReportScreen extends StatefulWidget {
  const KownerCreateReportScreen({super.key});

  @override
  State<KownerCreateReportScreen> createState() => _State();
}

class _State extends State<KownerCreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = KownerFirestoreService();
  final _minio = MinioService();
  final _picker = ImagePicker();

  // ── Form fields ──────────────────────────────────────────
  DateTime _date = DateTime.now();
  final _distributionTimeCtrl = TextEditingController();
  final _totalBeneficiariesCtrl = TextEditingController();
  final List<MenuItemModel> _menuItems = [];
  final List<File> _imageFiles = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _distributionTimeCtrl.dispose();
    _totalBeneficiariesCtrl.dispose();
    super.dispose();
  }

  // ── Pick date ────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Pick images ──────────────────────────────────────────
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _imageFiles.addAll(picked.map((x) => File(x.path))));
    }
  }

  // ── Add menu item dialog ─────────────────────────────────
  void _showAddMenuDialog() {
    final nameCtrl = TextEditingController();
    final portionCtrl = TextEditingController();
    final calCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text('Tambah Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: nameCtrl, label: 'Nama Menu'),
            const SizedBox(height: 10),
            _DialogField(
              ctrl: portionCtrl,
              label: 'Jumlah Porsi',
              isNumber: true,
            ),
            const SizedBox(height: 10),
            _DialogField(
              ctrl: calCtrl,
              label: 'Kalori per Porsi (opsional)',
              isNumber: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF8A8FA8)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || portionCtrl.text.isEmpty) return;
              setState(() {
                _menuItems.add(
                  MenuItemModel(
                    name: nameCtrl.text,
                    portionCount: int.parse(portionCtrl.text),
                    caloriesPerPortion: calCtrl.text.isNotEmpty
                        ? int.parse(calCtrl.text)
                        : null,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Tambah',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_menuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 menu.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload images to MinIO, collect URLs (objectPaths)
      final List<String> imageUrls = [];
      for (final file in _imageFiles) {
        final bytes = await file.readAsBytes();
        final objectPath =
            'reports/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final path = await _minio.uploadFile(
          objectPath: objectPath,
          fileStream: Stream.value(Uint8List.fromList(bytes)),
        );
        imageUrls.add(path);
      }

      // 2. Save report to Firestore
      await _svc.createReport(
        _date,
        _menuItems,
        int.parse(_totalBeneficiariesCtrl.text),
        _distributionTimeCtrl.text,
        imageUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        //Navigator.pop(context);
        setState(() {
          _date = DateTime.now();
          _menuItems.clear();
          _imageFiles.clear();
          _distributionTimeCtrl.clear();
          _totalBeneficiariesCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date picker ────────────────────────────────
              const _Label('Tanggal'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: _boxDecor(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF8A8FA8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMMM yyyy').format(_date),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Distribution time ──────────────────────────
              const _Label('Waktu Distribusi'),
              TextFormField(
                controller: _distributionTimeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('cth. 07:00 - 08:00'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // ── Total beneficiaries ────────────────────────
              const _Label('Total Penerima'),
              TextFormField(
                controller: _totalBeneficiariesCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('cth. 100'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v) == null) return 'Harus angka';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Menu items ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Label('Menu'),
                  TextButton.icon(
                    onPressed: _showAddMenuDialog,
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF6C63FF),
                      size: 18,
                    ),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
              if (_menuItems.isEmpty)
                const Text(
                  'Belum ada menu.',
                  style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 13),
                )
              else
                ..._menuItems.asMap().entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFF6C63FF),
                      size: 18,
                    ),
                    title: Text(
                      e.value.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${e.value.portionCount} porsi'
                      '${e.value.caloriesPerPortion != null ? ' · ${e.value.caloriesPerPortion} kal' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF8A8FA8),
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF8A8FA8),
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _menuItems.removeAt(e.key)),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Proof images ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Label('Bukti Foto'),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF6C63FF),
                      size: 18,
                    ),
                    label: const Text(
                      'Pilih Foto',
                      style: TextStyle(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
              if (_imageFiles.isEmpty)
                const Text(
                  'Belum ada foto.',
                  style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 13),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageFiles[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imageFiles.removeAt(i)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // ── Submit button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFF6C63FF,
                    ).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecor() => BoxDecoration(
    color: const Color(0xFF1C1F2E),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFF2A2D3E)),
  );

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8A8FA8)),
    filled: true,
    fillColor: const Color(0xFF1C1F2E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent),
  );
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isNumber;
  const _DialogField({
    required this.ctrl,
    required this.label,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8A8FA8)),
        filled: true,
        fillColor: const Color(0xFF0F1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
