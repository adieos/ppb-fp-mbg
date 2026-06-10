import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/kowner_firestore_service.dart';
import '../../services/minio_service.dart';

class KownerEditReportScreen extends StatefulWidget {
  final ReportModel report;
  const KownerEditReportScreen({super.key, required this.report});

  @override
  State<KownerEditReportScreen> createState() => _State();
}

class _State extends State<KownerEditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = KownerFirestoreService();
  final _minio = MinioService();
  final _picker = ImagePicker();

  // ── Form fields ──────────────────────────────────────────
  late DateTime _date;
  late TextEditingController _distributionTimeCtrl;
  late TextEditingController _totalBeneficiariesCtrl;
  late List<MenuItemModel> _menuItems;

  // existing URLs from Firestore (already uploaded)
  late List<String> _existingImageUrls;
  // new images picked from gallery (not yet uploaded)
  final List<File> _newImageFiles = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // pre-fill everything from the existing report
    final r = widget.report;
    _date = r.date;
    _distributionTimeCtrl = TextEditingController(text: r.distributionTime);
    _totalBeneficiariesCtrl = TextEditingController(
      text: r.totalBeneficiaries.toString(),
    );
    _menuItems = List.from(r.menuItems); // copy so we don't mutate original
    _existingImageUrls = List.from(r.proofImageUrls);
  }

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

  // ── Pick new images ──────────────────────────────────────
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _newImageFiles.addAll(picked.map((x) => File(x.path))));
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
      // 1. Upload any NEW images to MinIO
      final List<String> newUrls = [];
      for (final file in _newImageFiles) {
        final bytes = await file.readAsBytes();
        final objectPath =
            'reports/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final path = await _minio.uploadFile(
          objectPath: objectPath,
          fileStream: Stream.value(Uint8List.fromList(bytes)),
        );
        newUrls.add(path);
      }

      // 2. Merge existing + new image URLs
      final allImageUrls = [..._existingImageUrls, ...newUrls];

      // 3. Update Firestore
      await _svc.updateReport(
        widget.report.id,
        _date,
        _menuItems,
        int.parse(_totalBeneficiariesCtrl.text),
        _distributionTimeCtrl.text,
        allImageUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
          'Edit Laporan',
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
              // ── Date ──────────────────────────────────────
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

              // ── Existing images ────────────────────────────
              if (_existingImageUrls.isNotEmpty) ...[
                const _Label('Foto Sebelumnya'),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => FutureBuilder<String>(
                      future: _minio.getPresignedUrl(_existingImageUrls[i]),
                      builder: (context, snap) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: snap.hasData
                                ? Image.network(
                                    snap.data!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: const Color(0xFF2A2D3E),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF6C63FF),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _existingImageUrls.removeAt(i),
                              ),
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
                ),
                const SizedBox(height: 16),
              ],

              // ── New images ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Label('Tambah Foto Baru'),
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
              if (_newImageFiles.isEmpty)
                const Text(
                  'Belum ada foto baru.',
                  style: TextStyle(color: Color(0xFF8A8FA8), fontSize: 13),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImageFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _newImageFiles[i],
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
                                setState(() => _newImageFiles.removeAt(i)),
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
                          'Simpan Perubahan',
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
