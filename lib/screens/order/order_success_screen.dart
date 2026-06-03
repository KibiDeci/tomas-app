import 'package:flutter/material.dart';
import '../home/home_screen.dart';

const _kBlue = Color(0xFF2563EB);

class OrderSuccessScreen extends StatelessWidget {
  final String namaTukang;
  final String namaLayanan;
  final String tanggal;
  final String jam;
  final String alamat;
  final String metodeBayar;
  final String? idOrder;  // ← String?

  const OrderSuccessScreen({
    super.key,
    required this.namaTukang,
    required this.namaLayanan,
    required this.tanggal,
    required this.jam,
    required this.alamat,
    required this.metodeBayar,
    this.idOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 64),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pesanan Berhasil! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pesananmu sudah diterima.\nTukang akan segera menghubungimu.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _row(Icons.person_outline, namaTukang),
                      _row(Icons.work_outline, namaLayanan),
                      _row(Icons.calendar_today_outlined, '$tanggal, $jam WIB'),
                      _row(Icons.location_on_outlined, alamat),
                      _row(Icons.payment_outlined, metodeBayar),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen(initialTab: 2)),
                      (_) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Lihat Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  ),
                  child: const Text('Kembali ke Beranda',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _kBlue),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
          ],
        ),
      );
}