import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/tukang.dart';
import '../../models/layanan.dart';
import 'order_success_screen.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';

const _kBlue = Color(0xFF2563EB);
const _kBg = Color(0xFFF2F2F7);

class KonfirmasiScreen extends StatefulWidget {
  final Tukang tukang;
  final List<Layanan> layananList;
  final String selectedLayananId; // ← String
  final String selectedLayananNama;

  const KonfirmasiScreen({
    super.key,
    required this.tukang,
    required this.layananList,
    required this.selectedLayananId,
    required this.selectedLayananNama,
  });

  @override
  State<KonfirmasiScreen> createState() => _KonfirmasiScreenState();
}

class _KonfirmasiScreenState extends State<KonfirmasiScreen> {
  late String _layananId; // ← String
  late String _layananNama;
  String _durasi = '';
  String _metodeBayar = 'Tunai';
  String _alamat = 'Jl. Melati No. 12, RT 03/04, Surakarta';
  LatLng? _koordinat;
  DateTime _tanggal = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _jam = const TimeOfDay(hour: 8, minute: 0);
  final _deskripsiCtrl = TextEditingController();
  bool _loading = false;

  static const _durasiOptions = [
    '1 jam',
    '2 jam',
    '3 jam',
    '4 jam',
    'Sesuai pekerjaan',
  ];
  static const _metodeBayarOptions = [
    'Tunai',
    'Transfer Bank',
    'QRIS',
    'OVO',
    'GoPay',
  ];

  static const _quickTags = {
    'tukang': [
      'Perbaikan ringan',
      'Pasang baru',
      'Pengecekan',
      'Instalasi',
      'Servis rutin'
    ],
    'listrik': [
      'Instalasi listrik',
      'Ganti saklar',
      'Perbaikan korsleting',
      'Pasang lampu'
    ],
    'servis': ['Servis AC', 'Isi freon', 'Cuci AC', 'Ganti filter'],
    'cat': ['Cat ulang', 'Tambal dinding', 'Cat pagar', 'Cat interior'],
    'bersih': [
      'Bersih rumah',
      'Cuci sofa',
      'Bersih kamar mandi',
      'Cuci karpet'
    ],
    'antar': ['Antar barang', 'Jemput titipan', 'Kirim dokumen'],
    'foto': ['Foto produk', 'Foto pernikahan', 'Foto wisuda', 'Foto keluarga'],
  };

  List<String> get _currentTags {
    final kat = (widget.tukang.kategori ?? '').toLowerCase();
    for (final k in _quickTags.keys) {
      if (kat.contains(k)) return _quickTags[k]!;
    }
    return [
      'Perbaikan ringan',
      'Pasang baru',
      'Pengecekan',
      'Instalasi',
      'Servis rutin'
    ];
  }

  @override
  void initState() {
    super.initState();
    _layananId = widget.selectedLayananId;
    _layananNama = widget.selectedLayananNama;
  }

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  String get _tanggalStr =>
      '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}';

  String get _jamStr =>
      '${_jam.hour.toString().padLeft(2, '0')}:${_jam.minute.toString().padLeft(2, '0')}';

  String get _tanggalDisplay {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${_tanggal.day} ${months[_tanggal.month - 1]} ${_tanggal.year}';
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _tanggal = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _jam,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (t != null) setState(() => _jam = t);
  }

  Future<void> _submit() async {
    if (_alamat.trim().isEmpty) {
      _snack('Isi alamat pengerjaan dulu!');
      return;
    }
    if (_koordinat == null) {
      _snack('Pilih lokasi di peta!');
      return;
    }
    setState(() => _loading = true);
    try {
      final idOrder = await ApiService.createOrder(
        // ← named params, returns String
        idTukang: widget.tukang.idTukang,
        idLayanan: _layananId,
        alamat: _alamat,
        latitude: _koordinat!.latitude,
        longitude: _koordinat!.longitude,
        tanggalKerja: _tanggalStr,
        jamMulai: _jamStr,
        durasi: _durasi.isEmpty ? null : _durasi,
        deskripsi: _deskripsiCtrl.text.trim().isEmpty
            ? null
            : _deskripsiCtrl.text.trim(),
        metodeBayar: _metodeBayar,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            namaTukang: widget.tukang.nama,
            namaLayanan: _layananNama,
            tanggal: _tanggalDisplay,
            jam: _jamStr,
            alamat: _alamat,
            metodeBayar: _metodeBayar,
            idOrder: idOrder, // ← String
          ),
        ),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Gagal membuat pesanan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = widget.tukang;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tukang Info
          _card(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: t.fotoUrl != null
                      ? Image.network(
                          t.fotoUrl!,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              _avatarPlaceholder(t.nama), // ← fix
                        )
                      : _avatarPlaceholder(t.nama),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nama,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.work_outline,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(t.kategori ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(t.lokasi ?? 'Surakarta',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFACC15), size: 14),
                        const SizedBox(width: 3),
                        Text(t.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Layanan Picker
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jenis Layanan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.layananList.map((l) {
                    final active = l.idLayanan == _layananId;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _layananId = l.idLayanan; // ← String
                        _layananNama = l.namaLayanan;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? _kBlue : Colors.white,
                          border: Border.all(
                              color: active ? _kBlue : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(l.namaLayanan,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF374151),
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tanggal & Jam
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Waktu Pengerjaan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: _kBlue),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_tanggalDisplay,
                                  style: const TextStyle(fontSize: 13))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.access_time,
                              size: 16, color: _kBlue),
                          const SizedBox(width: 8),
                          Text('$_jamStr WIB',
                              style: const TextStyle(fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Durasi
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimasi Durasi',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durasiOptions.map((d) {
                    final active = d == _durasi;
                    return GestureDetector(
                      onTap: () => setState(() => _durasi = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? _kBlue : const Color(0xFFF9FAFB),
                          border: Border.all(
                              color: active ? _kBlue : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF6B7280))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Alamat
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat & Lokasi Pengerjaan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _alamatChip(
                        'Rumah', 'Jl. Melati No. 12, RT 03/04, Surakarta'),
                    _alamatChip(
                        'Kantor', 'Jl. Slamet Riyadi No. 45, Surakarta'),
                    _alamatChip('Lainnya', ''),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _alamat,
                  onChanged: (v) => _alamat = v,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Masukkan alamat lengkap...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBlue)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                MapPickerScreen(initial: _koordinat)),
                      );
                      if (picked != null && picked is LatLng) {
                        setState(() => _koordinat = picked);
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: Text(_koordinat == null
                        ? 'Pilih Lokasi di Peta'
                        : 'Lokasi: ${_koordinat!.latitude.toStringAsFixed(4)}, ${_koordinat!.longitude.toStringAsFixed(4)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Deskripsi
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deskripsi Pekerjaan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Opsional — ceritakan lebih detail kebutuhan kamu',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _currentTags
                      .map((tag) => GestureDetector(
                            onTap: () {
                              final cur = _deskripsiCtrl.text;
                              _deskripsiCtrl.text =
                                  cur.isEmpty ? tag : '$cur, $tag';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                border:
                                    Border.all(color: const Color(0xFFBFDBFE)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add,
                                        size: 12, color: _kBlue),
                                    const SizedBox(width: 4),
                                    Text(tag,
                                        style: const TextStyle(
                                            fontSize: 11, color: _kBlue)),
                                  ]),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deskripsiCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Perbaikan keran bocor di dapur...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBlue)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metode Bayar
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Metode Pembayaran',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                ..._metodeBayarOptions.map((m) => GestureDetector(
                      onTap: () => setState(() => _metodeBayar = m),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _metodeBayar == m
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                              color: _metodeBayar == m
                                  ? _kBlue
                                  : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(_metodeBayarIcon(m),
                              size: 20,
                              color: _metodeBayar == m ? _kBlue : Colors.grey),
                          const SizedBox(width: 12),
                          Text(m,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _metodeBayar == m
                                      ? _kBlue
                                      : const Color(0xFF374151))),
                          const Spacer(),
                          if (_metodeBayar == m)
                            const Icon(Icons.check_circle,
                                color: _kBlue, size: 18),
                        ]),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ringkasan
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Pesanan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _summaryRow('Tukang', t.nama),
                _summaryRow('Layanan', _layananNama),
                _summaryRow('Tanggal', _tanggalDisplay),
                _summaryRow('Jam', '$_jamStr WIB'),
                if (_durasi.isNotEmpty) _summaryRow('Durasi', _durasi),
                _summaryRow('Pembayaran', _metodeBayar),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Konfirmasi & Pesan Sekarang',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _avatarPlaceholder(String nama) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _kBlue)),
        ),
      );

  Widget _alamatChip(String label, String val) => GestureDetector(
        onTap: () {
          if (val.isNotEmpty) setState(() => _alamat = val);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _alamat == val && val.isNotEmpty
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF9FAFB),
            border: Border.all(
                color: _alamat == val && val.isNotEmpty
                    ? _kBlue
                    : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: _alamat == val && val.isNotEmpty
                      ? _kBlue
                      : const Color(0xFF6B7280))),
        ),
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937)))),
          ],
        ),
      );

  IconData _metodeBayarIcon(String m) {
    switch (m) {
      case 'Transfer Bank':
        return Icons.account_balance_outlined;
      case 'QRIS':
        return Icons.qr_code;
      case 'OVO':
        return Icons.wallet;
      case 'GoPay':
        return Icons.payment;
      default:
        return Icons.money;
    }
  }
}
