import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _user;
  bool _loading = false;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get uid => _auth.currentUser?.uid;

  // Konversi no HP ke format email untuk Firebase Auth
  String _toEmail(String noHp) {
    final cleaned = noHp.replaceAll(RegExp(r'[^0-9]'), '');
    return '$cleaned@tomas.app';
  }

  Future<void> tryAutoLogin() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _user = {'uid': firebaseUser.uid, ...doc.data()!};
        notifyListeners();
        _saveFcmToken(firebaseUser.uid);
      }
    } catch (_) {}
  }

  Future<void> login(String noHp, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final email = _toEmail(noHp);
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      _user = {'uid': cred.user!.uid, ...doc.data()!};
      _saveFcmToken(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String nama, String noHp, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final email = _toEmail(noHp);
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'nama': nama,
        'no_hp': noHp,
        'alamat': '',
        'foto_url': null,
        'created_at': FieldValue.serverTimestamp(),
      };
      await _db.collection('users').doc(cred.user!.uid).set(userData);

      _user = {'uid': cred.user!.uid, ...userData};
      _saveFcmToken(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({'fcm_token': null});
    }
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> updated) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(updated);
    _user = {'uid': uid, ..._user ?? {}, ...updated};
    notifyListeners();
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcm_token': token});
      }
    } catch (_) {}
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Nomor HP sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'invalid-credential':
        return 'Nomor HP atau password salah.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
