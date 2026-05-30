import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
      setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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

  Future<void> _markOne(String id, int index) async {  // ← String
    await ApiService.markNotifRead(id);
    setState(() {
      _list[index] = {
        ...(_list[index] as Map<String, dynamic>),
        'dibaca': true,
      };
    });
  }

  IconData _iconForType(String? tipe) {
    switch (tipe) {
      case 'order': return Icons.receipt_long;
      case 'chat': return Icons.chat_bubble;
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String? tipe) {
    switch (tipe) {
      case 'order': return Colors.green;
      case 'chat': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _list.where((n) => n['dibaca'] == false).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAll,
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
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
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
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
                  return InkWell(
                    onTap: read
                        ? null
                        : () => _markOne(n['id_notif'] as String, i),  // ← String
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: read ? null : Border.all(color: _kBlue.withOpacity(0.3)),
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
                            width: 40,
                            height: 40,
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
                                          fontWeight: read ? FontWeight.w500 : FontWeight.bold,
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
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n['pesan'] as String? ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(n['created_at'] as String?),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
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

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return '';
    }
  }
}