import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseDatabase? db,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ??
            FirebaseDatabase.instanceFor(
              app: FirebaseDatabase.instance.app,
              databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
            ),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  /// Stream data pengguna dari Realtime Database node users/{uid}
  Stream<AppUser?> watchUser(String uid) {
    return _db.ref('users/$uid').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return AppUser.fromMap(uid, event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Masuk dengan email & password
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final snapshot = await _db.ref('users/${user.uid}').get();

      if (snapshot.exists && snapshot.value is Map) {
        return AppUser.fromMap(user.uid, snapshot.value as Map);
      } else {
        // Fallback jika node belum ada
        final newUser = AppUser(
          uid: user.uid,
          displayName: user.displayName ?? email.split('@').first,
          email: user.email ?? email,
          provider: 'password',
          photoUrl: user.photoURL ?? '',
        );
        await _db.ref('users/${user.uid}').set({
          'displayName': newUser.displayName,
          'email': newUser.email,
          'provider': 'password',
          'photoUrl': '',
          'createdAt': ServerValue.timestamp,
          'settings': newUser.settings.toMap(),
        });
        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Daftar dengan email & password
  Future<AppUser> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName.trim());

      final appUser = AppUser(
        uid: user.uid,
        displayName: displayName.trim(),
        email: email.trim(),
        provider: 'password',
        photoUrl: '',
        settings: const UserSettings(),
      );

      await _db.ref('users/${user.uid}').set({
        'displayName': appUser.displayName,
        'email': appUser.email,
        'provider': 'password',
        'photoUrl': '',
        'createdAt': ServerValue.timestamp,
        'settings': appUser.settings.toMap(),
      });

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Masuk via Google Sign-In
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw 'Login dengan Google dibatalkan';
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final snapshot = await _db.ref('users/${user.uid}').get();

      if (snapshot.exists && snapshot.value is Map) {
        final existing = AppUser.fromMap(user.uid, snapshot.value as Map);
        return (user: existing, isNewUser: false);
      } else {
        final displayName = user.displayName ?? googleAccount.displayName ?? 'Pengguna Kerkom';
        final appUser = AppUser(
          uid: user.uid,
          displayName: displayName,
          email: user.email ?? googleAccount.email,
          provider: 'google',
          photoUrl: user.photoURL ?? googleAccount.photoUrl ?? '',
          settings: const UserSettings(),
        );

        await _db.ref('users/${user.uid}').set({
          'displayName': appUser.displayName,
          'email': appUser.email,
          'provider': 'google',
          'photoUrl': appUser.photoUrl,
          'createdAt': ServerValue.timestamp,
          'settings': appUser.settings.toMap(),
        });

        return (user: appUser, isNewUser: true);
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
      debugPrint('Google Sign In error: $e');
      throw 'Gagal login via Google. Silakan coba lagi.';
    }
  }

  /// Lengkapi profil (untuk Google user pertama kali / S03)
  Future<void> completeProfile(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum terautentikasi';
    await user.updateDisplayName(displayName.trim());
    await _db.ref('users/${user.uid}/displayName').set(displayName.trim());
  }

  /// Perbarui nama profil dan avatar pengguna (S15)
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum terautentikasi';

    final updates = <String, dynamic>{};
    if (displayName != null) {
      await user.updateDisplayName(displayName.trim());
      updates['displayName'] = displayName.trim();
    }
    if (photoUrl != null) {
      try {
        await user.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
      } catch (_) {}
      updates['photoUrl'] = photoUrl;
    }
    if (updates.isNotEmpty) {
      await _db.ref('users/${user.uid}').update(updates);
    }
  }

  /// Perbarui preferensi sinkronisasi kalender (S21)
  Future<void> updateCalendarSettings({
    bool? googleCalendarConnected,
    bool? outlookCalendarConnected,
    bool? autoSyncCalendar,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';
    final updates = <String, dynamic>{};
    if (googleCalendarConnected != null) {
      updates['googleCalendarConnected'] = googleCalendarConnected;
    }
    if (outlookCalendarConnected != null) {
      updates['outlookCalendarConnected'] = outlookCalendarConnected;
    }
    if (autoSyncCalendar != null) {
      updates['autoSyncCalendar'] = autoSyncCalendar;
    }
    if (updates.isNotEmpty) {
      await _db.ref('users/${user.uid}/settings').update(updates);
    }
  }

  /// Perbarui nama profil pengguna (S15)
  Future<void> updateDisplayName(String displayName) async {
    await updateProfile(displayName: displayName);
  }

  /// Perbarui toleransi kemiringan sensor (S16)
  Future<void> updateTiltToleranceDeg(double tiltToleranceDeg) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';
    await _db.ref('users/${user.uid}/settings/tiltToleranceDeg').set(tiltToleranceDeg);
  }

  /// Perbarui izin pemantauan latar belakang (S19) ('always' | 'whileSession' | 'once')
  Future<void> updateMonitorPermission(String monitorPermission) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';
    await _db.ref('users/${user.uid}/settings/monitorPermission').set(monitorPermission);
  }

  /// Perbarui pengaturan alarm (S17) (alarmMode & volume)
  Future<void> updateAlarmSettings({
    required String alarmMode,
    required double volume,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';
    await _db.ref('users/${user.uid}/settings').update({
      'alarmMode': alarmMode,
      'volume': volume.clamp(0.0, 1.0),
    });
  }

  /// Kirim email tautan reset kata sandi via Firebase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw 'Format email tidak valid.';
      }
      // Untuk keamanan pengguna, jangan membocorkan status registrasi email
    } catch (e) {
      if (e is String) rethrow;
      throw 'Gagal mengirim email reset kata sandi. Silakan coba lagi.';
    }
  }

  /// Keluar dari akun
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Hapus akun pengguna (menghapus users/{uid} & akun auth)
  Future<void> deleteAccount({String? passwordForReauth}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';

    try {
      if (passwordForReauth != null && user.email != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordForReauth,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // Hapus data pengguna di Realtime Database
      await _db.ref('users/${user.uid}').remove();
      // Hapus akun dari Firebase Auth
      await user.delete();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'requires-recent-login';
      }
      throw _mapFirebaseAuthError(e);
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Pendaftaran dengan Email/Password belum diaktifkan di Firebase Console. Buka Authentication > Sign-in method lalu aktifkan Email/Password.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah. Cek kredensial Anda.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 8 karakter.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan coba beberapa saat lagi.';
      default:
        return e.message ?? 'Terjadi kesalahan pada autentikasi.';
    }
  }
}
