import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/tukang.dart';
import '../../models/layanan.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../order/konfirmasi_screen.dart';

class TukangDetailScreen extends StatefulWidget {
  final String idTukang;
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
  String? _selectedLayanan;
  int _currentPhotoPage = 0;
  bool _descExpanded = false;

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
      final isFav = await ApiService.toggleFavorit(widget.idTukang);
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
          idTukang: widget.idTukang,
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

  // ── Deteksi apakah URL adalah PDF ────────────────────────────────────────
  // Cloudinary menyimpan PDF di path /raw/upload/, sementara gambar di /image/upload/
  bool _isPdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/raw/upload/') || lower.endsWith('.pdf');
  }

  // ── Buka portfolio di browser / PDF viewer eksternal ─────────────────────
  Future<void> _openPortfolio(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tidak dapat membuka portfolio. Pastikan ada aplikasi PDF viewer.'),
        ),
      );
    }
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
    final photos = t.fotoPortfolioUrls ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── HEADER: Foto Pengerjaan ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Carousel foto pengerjaan
                  photos.isNotEmpty
                      ? PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhotoPage = i),
                          itemBuilder: (ctx, i) => Image.network(
                            photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _workPhotoPlaceholder(),
                          ),
                        )
                      : _workPhotoPlaceholder(),
                  // Gradient overlay bawah
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Label foto pengerjaan
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_outlined,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            photos.isEmpty
                                ? 'Foto Pengerjaan'
                                : 'Foto Pengerjaan (${photos.length})',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dot indicator jika banyak foto
                  if (photos.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Row(
                        children: List.generate(
                          photos.length,
                          (i) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoPage == i
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KARTU: Foto Profil + Nama ────────────────────────────
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: t.fotoUrl != null
                                  ? Image.network(
                                      t.fotoUrl!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _profilePlaceholder(),
                                    )
                                  : _profilePlaceholder(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.nama,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (t.kategori != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      t.kategori!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: t.statusAktif
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFF3F4F6),
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

                        const Divider(height: 24),

                        // Statistik: Rating | Pesanan | Tarif
                        Row(
                          children: [
                            _statItem(Icons.star, const Color(0xFFF59E0B),
                                t.rating.toStringAsFixed(1), 'Rating'),
                            _vDivider(),
                            _statItem(
                              Icons.work_outline,
                              const Color(0xFF2563EB),
                              t.jumlahOrder != null ? '${t.jumlahOrder}' : '-',
                              'Pesanan',
                            ),
                            _vDivider(),
                            _statItem(
                              Icons.attach_money,
                              const Color(0xFF10B981),
                              t.tarif != null
                                  ? 'Rp${_formatPrice(t.tarif!)}'
                                  : 'Nego',
                              'Tarif',
                            ),
                          ],
                        ),

                        if (t.lokasi != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  t.lokasi!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── KARTU: Tentang Tukang ────────────────────────────────
                  if (t.bio != null || t.pengalaman != null || t.noHp != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.info_outline, 'Tentang Tukang'),
                          const SizedBox(height: 10),
                          if (t.bio != null) ...[
                            Text(
                              _descExpanded
                                  ? t.bio!
                                  : (t.bio!.length > 150
                                      ? '${t.bio!.substring(0, 150)}...'
                                      : t.bio!),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.6),
                            ),
                            if (t.bio!.length > 150)
                              GestureDetector(
                                onTap: () => setState(
                                    () => _descExpanded = !_descExpanded),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _descExpanded
                                        ? 'Lihat lebih sedikit'
                                        : 'Lihat selengkapnya',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          if (t.pengalaman != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: const [
                                Icon(Icons.verified_outlined,
                                    size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text('Pengalaman',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.pengalaman!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.5),
                            ),
                          ],
                          if (t.noHp != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                Text(
                                  t.noHp!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (t.bio != null || t.pengalaman != null || t.noHp != null)
                    const SizedBox(height: 12),

                  // ── KARTU: Portfolio Foto (dari field foto_portfolio) ─────
                  if (photos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(Icons.photo_library_outlined,
                              'Portfolio Pengerjaan'),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: photos.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (ctx, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GestureDetector(
                                onTap: () => _showPhotoFull(photos, i),
                                child: Image.network(
                                  photos[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF0F0F0),
                                    child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (photos.isNotEmpty) const SizedBox(height: 12),

                  // ══ KARTU: Portfolio Dokumen (dari field portfolio_url) ══
                  // Menampilkan preview PDF atau gambar yang diupload admin.
                  if (t.portfolioUrl != null) ...[
                    _buildPortfolioCard(t.portfolioUrl!),
                    const SizedBox(height: 12),
                  ],

                  // ── KARTU: Lokasi Area Kerja ─────────────────────────────
                  if (t.latitude != null && t.longitude != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: _sectionTitle(
                                Icons.location_on, 'Lokasi Area Kerja'),
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
                                    child: Text(
                                      t.alamat!,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // ── KARTU: Pilih Layanan ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(Icons.build_outlined, 'Pilih Layanan'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _layanan.map((l) {
                            final selected = _selectedLayanan == l.idLayanan;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedLayanan = l.idLayanan),
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

                  // ── TOMBOL AKSI ───────────────────────────────────────────
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

  // ══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  /// Card utama portfolio — memilih antara tampilan PDF atau gambar
  /// berdasarkan deteksi URL.
  Widget _buildPortfolioCard(String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.folder_copy_outlined, 'Portfolio'),
          const SizedBox(height: 12),
          _isPdfUrl(url) ? _buildPdfPreview(url) : _buildImagePreview(url),
        ],
      ),
    );
  }

  /// Tampilan preview untuk file PDF.
  ///
  /// Karena Flutter tidak bisa me-render PDF secara native tanpa package
  /// tambahan, kita tampilkan card informatif yang bisa dibuka via url_launcher
  /// ke browser / aplikasi PDF viewer yang terpasang di perangkat.
  Widget _buildPdfPreview(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card utama PDF
        GestureDetector(
          onTap: () => _openPortfolio(url),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Row(
              children: [
                // Ikon PDF
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                // Teks info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Portfolio PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ketuk untuk membuka dokumen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ikon buka
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol alternatif yang lebih jelas
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openPortfolio(url),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Buka / Unduh Portfolio PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tampilan preview untuk file gambar (PNG / JPG).
  ///
  /// Menampilkan gambar penuh dengan kemampuan tap untuk melihat fullscreen.
  Widget _buildImagePreview(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail gambar — tap → fullscreen
        GestureDetector(
          onTap: () => _showPhotoFull([url], 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  url,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 220,
                      color: const Color(0xFFF0F6FF),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF2563EB),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text('Gagal memuat gambar',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                // Label "Ketuk untuk perbesar"
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.zoom_in_rounded,
                            size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'Ketuk untuk memperbesar',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      );

  Widget _statItem(
          IconData icon, Color iconColor, String value, String label) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937)),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );

  Widget _vDivider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFFE5E7EB),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _workPhotoPlaceholder() => Container(
        color: const Color(0xFF1E3A5F),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_library_outlined, size: 50, color: Colors.white30),
            SizedBox(height: 8),
            Text(
              'Belum ada foto pengerjaan',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _profilePlaceholder() => Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 36, color: Colors.grey),
      );

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}Jt';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  void _showPhotoFull(List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (ctx, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    photos[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                        color: Colors.white54, size: 60),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
