import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../models/tukang.dart';
import '../../models/layanan.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../order/konfirmasi_screen.dart';

class TukangDetailScreen extends StatefulWidget {
  final String idTukang; // ← String

  const TukangDetailScreen({super.key, required this.idTukang});

  @override
  State<TukangDetailScreen> createState() => _TukangDetailScreenState();
}

class _TukangDetailScreenState extends State<TukangDetailScreen> {
  Tukang? _tukang;
  List<Layanan> _layanan = [];
  bool _loading = true;
  bool _favorited = false;
  bool _favLoading = false;
  String? _selectedLayanan; // ← String?

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Future.wait([
        ApiService.getTukangDetail(widget.idTukang),
        ApiService.getLayanan(),
      ]);
      final tukangData = data[0] as Map<String, dynamic>;
      final layananData = data[1] as List;

      bool favorited = false;
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      if (isLoggedIn) {
        try {
          favorited = await ApiService.checkFavorit(widget.idTukang);
        } catch (_) {}
      }

      setState(() {
        _tukang = Tukang.fromJson(tukangData);
        _layanan = layananData
            .map((l) => Layanan.fromJson(l as Map<String, dynamic>))
            .toList();
        _favorited = favorited;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFav() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      _requireLogin();
      return;
    }
    setState(() => _favLoading = true);
    try {
      final isFav = await ApiService.toggleFavorit(widget.idTukang); // ← bool
      setState(() => _favorited = isFav);
    } catch (_) {
    } finally {
      setState(() => _favLoading = false);
    }
  }

  Future<void> _order() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      _requireLogin();
      return;
    }
    if (_selectedLayanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih layanan terlebih dahulu')),
      );
      return;
    }
    final layanan = _layanan.firstWhere((l) => l.idLayanan == _selectedLayanan);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KonfirmasiScreen(
          tukang: _tukang!,
          layananList: _layanan,
          selectedLayananId: _selectedLayanan!,
          selectedLayananNama: layanan.namaLayanan,
        ),
      ),
    );
  }

  void _chat() {
    if (!context.read<AuthProvider>().isLoggedIn) {
      _requireLogin();
      return;
    }
    if (_tukang == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          idTukang: widget.idTukang, // ← sudah String
          namaTukang: _tukang!.nama,
          fotoUrl: _tukang!.fotoUrl,
        ),
      ),
    );
  }

  void _requireLogin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text('Silakan login untuk melanjutkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B47)),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tukang == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tukang tidak ditemukan.')),
      );
    }

    final t = _tukang!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            actions: [
              _favLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _favorited ? Icons.favorite : Icons.favorite_outline,
                        color: _favorited ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFav,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: t.fotoUrl != null
                  ? Image.network(
                      t.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          _headerPlaceholder(), // ← fix
                    )
                  : _headerPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & rating
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.nama,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.statusAktif
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF9CA3AF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t.statusAktif ? '● Aktif' : '● Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.statusAktif
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              t.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937)),
                            ),
                            const SizedBox(width: 16),
                            if (t.lokasi != null) ...[
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(t.lokasi!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                            ],
                          ],
                        ),
                        if (t.bio != null) ...[
                          const SizedBox(height: 12),
                          Text(t.bio!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.5)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (t.latitude != null && t.longitude != null)
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(children: [
                              const Icon(Icons.location_on,
                                  color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              const Text('Lokasi Area Kerja',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937))),
                            ]),
                          ),
                          SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    LatLng(t.latitude!, t.longitude!),
                                initialZoom: 14,
                                interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.tomas.tomas_app',
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: LatLng(t.latitude!, t.longitude!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_pin,
                                        color: Color(0xFF2563EB), size: 40),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          if (t.alamat != null)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 14),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.home_outlined,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(t.alamat!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54))),
                                  ]),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Layanan picker
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pilih Layanan',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _layanan.map((l) {
                            final selected = _selectedLayanan == l.idLayanan;
                            return GestureDetector(
                              onTap: () => setState(
                                () =>
                                    _selectedLayanan = l.idLayanan, // ← String
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l.namaLayanan,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _chat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _order,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Pesan Sekarang',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPlaceholder() => Container(
        color: const Color(0xFF2563EB),
        child: const Center(
          child: Icon(Icons.person, size: 80, color: Colors.white30),
        ),
      );
}
