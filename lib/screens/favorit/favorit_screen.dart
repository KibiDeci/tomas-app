import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/tukang.dart';
import '../tukang/tukang_detail_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  List<Tukang> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getFavorit();
      setState(() {
        _list = data.map((f) => Tukang.fromJson(f)).toList(); // ← langsung map
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(String idTukang) async {
    // ← String
    try {
      await ApiService.toggleFavorit(idTukang);
      setState(() => _list.removeWhere((t) => t.idTukang == idTukang));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Favorit',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_outline,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada favorit',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final t = _list[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TukangDetailScreen(idTukang: t.idTukang)),
                        ).then((_) => _load()),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: t.fotoUrl != null
                                    ? Image.network(
                                        t.fotoUrl!,
                                        width: 60, height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            _ph(), // ← fix
                                      )
                                    : _ph(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.nama,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937))),
                                    const SizedBox(height: 3),
                                    Text(t.kategori ?? '',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    if (t.lokasi != null) ...[
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 3),
                                        Text(t.lokasi!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red, size: 22),
                                onPressed: () => _remove(t.idTukang),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _ph() => Container(
        width: 60,
        height: 60,
        color: const Color(0xFFF2F2F7),
        child: const Icon(Icons.person, color: Colors.grey),
      );
}
