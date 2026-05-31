import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../order/order_list_screen.dart';

const _kBlue = Color(0xFF2563EB);

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});
  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getNotifikasi();
      if (!mounted) return;
      setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAll() async {
    await ApiService.markAllNotifRead();
    setState(() {
      _list = _list
          .map((n) => {...(n as Map<String, dynamic>), 'dibaca': true})
          .toList();
    });
  }

  Future<void> _markOne(String id, int index) async {
    await ApiService.markNotifRead(id);
    setState(() {
      _list[index] = {
        ...(_list[index] as Map<String, dynamic>),
        'dibaca': true
      };
    });
  }

  IconData _iconForType(String? tipe) {
    switch (tipe) {
      case 'order':
        return Icons.receipt_long;
      case 'chat':
        return Icons.chat_bubble;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? tipe) {
    switch (tipe) {
      case 'order':
        return const Color(0xFF2563EB);
      case 'chat':
        return Colors.green;
      case 'promo':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      DateTime dt;
      if (ts is String) {
        dt = DateTime.parse(ts).toLocal();
      } else {
        dt = (ts as dynamic).toDate() as DateTime;
      }
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _list.where((n) => n['dibaca'] == false).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAll,
              child: const Text('Tandai semua dibaca',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : _list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada notifikasi',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final n = _list[i] as Map<String, dynamic>;
                      final read = n['dibaca'] == true;
                      final tipe = n['tipe'] as String?;
                      final idOrder = n['id_order'] as String?;

                      return InkWell(
                        onTap: () {
                          if (!read) _markOne(n['id_notif'] as String, i);
                          // Navigasi ke detail pesanan jika notif tipe order
                          if (tipe == 'order') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrderListScreen(),
                                ));
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                read ? Colors.white : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: read
                                ? Border.all(color: const Color(0xFFE5E7EB))
                                : Border.all(color: _kBlue.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _colorForType(tipe).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconForType(tipe),
                                    color: _colorForType(tipe), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['judul'] as String? ?? '',
                                            style: TextStyle(
                                              fontWeight: read
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              fontSize: 13,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                        if (!read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: _kBlue,
                                                shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n['pesan'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          height: 1.4),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatTime(n['created_at']),
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                        if (tipe == 'order') ...[
                                          const SizedBox(width: 8),
                                          const Text('• Lihat Pesanan',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: _kBlue,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (tipe == 'order')
                                const Icon(Icons.chevron_right,
                                    color: Color(0xFF9CA3AF), size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
