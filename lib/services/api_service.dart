import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  static String get _uid => _auth.currentUser!.uid;

  // ── Layanan ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLayanan() async {
    final snap = await _db
        .collection('layanan')
        .orderBy('urutan')
        .get();
    return snap.docs
        .map((d) => {'id_layanan': d.id, ...d.data()})
        .toList();
  }

  // ── Tukang ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTukang({
    String? q,
    String? layanan,
  }) async {
    Query query = _db.collection('tukang');
    if (layanan != null && layanan.isNotEmpty) {
      query = query.where('kategori', isEqualTo: layanan);
    }
    final snap = await query.get();
    var list = snap.docs
        .map((d) => {'id_tukang': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
    if (q != null && q.isNotEmpty) {
      list = list
          .where((t) => (t['nama'] as String)
              .toLowerCase()
              .contains(q.toLowerCase()))
          .toList();
    }
    return list;
  }

  static Future<Map<String, dynamic>> getTukangDetail(String idTukang) async {
    final doc = await _db.collection('tukang').doc(idTukang).get();
    if (!doc.exists) throw Exception('Tukang tidak ditemukan.');
    return {'id_tukang': doc.id, ...doc.data()!};
  }

  static Future<List<Map<String, dynamic>>> getTukangByLayanan() async {
    final layananList = await getLayanan();
    final result = <Map<String, dynamic>>[];
    for (final l in layananList) {
      final snap = await _db
          .collection('tukang')
          .where('kategori', isEqualTo: l['nama_layanan'])
          .where('status_aktif', isEqualTo: true)
          .limit(10)
          .get();
      final tukangList = snap.docs
          .map((d) => {'id_tukang': d.id, ...d.data()})
          .toList();
      if (tukangList.isNotEmpty) {
        result.add({'layanan': l, 'tukang': tukangList});
      }
    }
    return result;
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final snap = await _db
        .collection('orders')
        .where('id_user', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .get();

    final orders = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final tukangDoc =
          await _db.collection('tukang').doc(data['id_tukang']).get();
      final layananDoc =
          await _db.collection('layanan').doc(data['id_layanan']).get();
      final payDoc =
          await _db.collection('pembayaran').doc(doc.id).get();
      final reviewSnap = await _db
          .collection('reviews')
          .where('id_order', isEqualTo: doc.id)
          .limit(1)
          .get();

      orders.add({
        'id_order': doc.id,
        'tukang': tukangDoc.exists
            ? {'id_tukang': tukangDoc.id, ...tukangDoc.data()!}
            : null,
        'layanan': layananDoc.exists
            ? {'id_layanan': layananDoc.id, ...layananDoc.data()!}
            : null,
        'pembayaran':
            payDoc.exists ? payDoc.data() : {'status': 'unpaid'},
        'has_review': reviewSnap.docs.isNotEmpty,
        ...data,
      });
    }
    return orders;
  }

  static Future<String> createOrder({
    required String idTukang,
    required String idLayanan,
    String? alamat,
    double? latitude,
    double? longitude,
    String? tanggalKerja,
    String? jamMulai,
    String? durasi,
    String? deskripsi,
    String? metodeBayar,
  }) async {
    final ref = await _db.collection('orders').add({
      'id_user': _uid,
      'id_tukang': idTukang,
      'id_layanan': idLayanan,
      if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (tanggalKerja != null) 'tanggal_kerja': tanggalKerja,
      if (jamMulai != null) 'jam_mulai': jamMulai,
      if (durasi != null) 'durasi': durasi,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (metodeBayar != null) 'metode_bayar': metodeBayar,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    // Buat dokumen pembayaran awal
    await _db.collection('pembayaran').doc(ref.id).set({
      'id_order': ref.id,
      'status': 'unpaid',
      'jumlah': 0,
    });

    // Buat notifikasi
    await _createNotifikasi(
      judul: 'Pesanan Dibuat',
      pesan: 'Pesanan kamu telah berhasil dibuat.',
      tipe: 'order',
    );

    return ref.id;
  }

  // ── Reviews ──────────────────────────────────────────────────────────────

  static Future<void> submitReview({
    required String idOrder,
    required String idTukang,
    required int rating,
    String? komentar,
  }) async {
    await _db.collection('reviews').add({
      'id_order': idOrder,
      'id_tukang': idTukang,
      'id_user': _uid,
      'rating': rating,
      if (komentar != null) 'komentar': komentar,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Update rata-rata rating tukang
    final snap = await _db
        .collection('reviews')
        .where('id_tukang', isEqualTo: idTukang)
        .get();
    final ratings = snap.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    await _db.collection('tukang').doc(idTukang).update({'rating': avg});
  }

  // ── Favorit ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFavorit() async {
    final snap = await _db
        .collection('favorit')
        .where('id_user', isEqualTo: _uid)
        .get();

    final result = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final idTukang = doc.data()['id_tukang'] as String;
      final tukangDoc =
          await _db.collection('tukang').doc(idTukang).get();
      if (tukangDoc.exists) {
        result.add({'id_tukang': tukangDoc.id, ...tukangDoc.data()!});
      }
    }
    return result;
  }

  static Future<bool> checkFavorit(String idTukang) async {
    final snap = await _db
        .collection('favorit')
        .where('id_user', isEqualTo: _uid)
        .where('id_tukang', isEqualTo: idTukang)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<bool> toggleFavorit(String idTukang) async {
    final snap = await _db
        .collection('favorit')
        .where('id_user', isEqualTo: _uid)
        .where('id_tukang', isEqualTo: idTukang)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
      return false; // sudah unfavorite
    } else {
      await _db.collection('favorit').add({
        'id_user': _uid,
        'id_tukang': idTukang,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true; // sudah favorite
    }
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  static String _chatDocId(String idTukang) => '${idTukang}_$_uid';

  /// Stream realtime untuk pesan chat
  static Stream<List<Map<String, dynamic>>> chatStream(String idTukang) {
    return _db
        .collection('chat')
        .doc(_chatDocId(idTukang))
        .collection('messages')
        .orderBy('created_at')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<List<Map<String, dynamic>>> getChatList() async {
    final snap = await _db
        .collection('chat')
        .where('id_user', isEqualTo: _uid)
        .orderBy('last_message_at', descending: true)
        .get();

    final result = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final tukangDoc =
          await _db.collection('tukang').doc(data['id_tukang']).get();
      if (tukangDoc.exists) {
        result.add({
          'tukang': {'id_tukang': tukangDoc.id, ...tukangDoc.data()!},
          'last_message': data['last_message'],
          'last_message_at': data['last_message_at'],
        });
      }
    }
    return result;
  }

  static Future<void> sendMessage(String idTukang, String pesan) async {
    final chatRef =
        _db.collection('chat').doc(_chatDocId(idTukang));

    await chatRef.collection('messages').add({
      'pesan': pesan,
      'dari_user': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'id_user': _uid,
      'id_tukang': idTukang,
      'last_message': pesan,
      'last_message_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Pembayaran ───────────────────────────────────────────────────────────

  static Future<void> bayar({
    required String idOrder,
    required String nomorReferensi,
    required double jumlah,
  }) async {
    await _db.collection('pembayaran').doc(idOrder).set({
      'id_order': idOrder,
      'jumlah': jumlah,
      'status': 'paid',
      'nomor_referensi': nomorReferensi,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _createNotifikasi(
      judul: 'Pembayaran Berhasil',
      pesan: 'Pembayaran untuk pesanan #$idOrder berhasil.',
      tipe: 'order',
    );
  }

  static Future<Map<String, dynamic>> getPaymentStatus(
      String idOrder) async {
    final doc =
        await _db.collection('pembayaran').doc(idOrder).get();
    return doc.exists ? doc.data()! : {'status': 'unpaid'};
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return {'uid': _uid, ...doc.data()!};
  }

  static Future<void> updateProfile({
    String? nama,
    String? noHp,
    String? alamat,
  }) async {
    final data = <String, dynamic>{};
    if (nama != null && nama.isNotEmpty) data['nama'] = nama;
    if (noHp != null && noHp.isNotEmpty) data['no_hp'] = noHp;
    if (alamat != null) data['alamat'] = alamat;
    await _db.collection('users').doc(_uid).update(data);
  }

  static Future<String?> uploadFotoProfil(File file) async {
    final ref = _storage.ref().child('users/$_uid/foto_profil.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _db
        .collection('users')
        .doc(_uid)
        .update({'foto_url': url});
    return url;
  }

  // ── Notifikasi ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotifikasi() async {
    final snap = await _db
        .collection('notifikasi')
        .where('id_user', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id_notif': d.id, ...d.data()})
        .toList();
  }

  static Future<int> getUnreadCount() async {
    final snap = await _db
        .collection('notifikasi')
        .where('id_user', isEqualTo: _uid)
        .where('dibaca', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  static Future<void> markNotifRead(String id) async {
    await _db
        .collection('notifikasi')
        .doc(id)
        .update({'dibaca': true});
  }

  static Future<void> markAllNotifRead() async {
    final snap = await _db
        .collection('notifikasi')
        .where('id_user', isEqualTo: _uid)
        .where('dibaca', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'dibaca': true});
    }
    await batch.commit();
  }

  static Future<void> _createNotifikasi({
    required String judul,
    required String pesan,
    required String tipe,
  }) async {
    await _db.collection('notifikasi').add({
      'id_user': _uid,
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'dibaca': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

// Alias agar semua screen lama yang pakai ApiService tidak perlu diubah nama
typedef ApiService = FirebaseService;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}