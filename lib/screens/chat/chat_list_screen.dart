import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getChatList();
      if (!mounted) return;
      setState(() {
        _chats = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Chat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
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
          : _chats.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada percakapan',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _chats.length,
                itemBuilder: (_, i) {
                  final item = _chats[i] as Map<String, dynamic>;
                  final tukang = item['tukang'] as Map<String, dynamic>;
                  return _ChatItem(
                    tukang: tukang,
                    lastMessage: item['last_message'] as String? ?? '',
                    unread: item['unread'] as int? ?? 0,
                  );
                },
              ),
            ),
    );
  }
}

class _ChatItem extends StatelessWidget {
  final Map<String, dynamic> tukang;
  final String lastMessage;
  final int unread;

  const _ChatItem({
    required this.tukang,
    required this.lastMessage,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            idTukang: tukang['id_tukang'].toString(),  // ← .toString() bukan as int
            namaTukang: tukang['nama'] as String,
            fotoUrl: tukang['foto_url'] as String?,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: tukang['foto_url'] != null
                  ? Image.network(
                      tukang['foto_url'],
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _ph(),  // ← fix nama unik
                    )
                  : _ph(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tukang['nama'] as String,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 3),
                  Text(lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
                child: Text('$unread',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(
        width: 52, height: 52,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F2F7)),
        child: const Icon(Icons.person, color: Colors.grey),
      );
}