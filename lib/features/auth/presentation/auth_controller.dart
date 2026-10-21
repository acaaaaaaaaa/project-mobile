import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream state login Firebase Auth (User?)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider tunggal data pengguna saat ini (uid, displayName, photoUrl, settings)
/// Di-stream langsung dari Realtime Database node users/{uid}.
/// Bagian aplikasi manapun TIDAK BOLEH menyimpan salinan nama sendiri secara independen.
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* repo.watchUser(user.uid);
});
