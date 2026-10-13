import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/room/presentation/room_controller.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  void initialize(WidgetRef ref, GoRouter router) {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri, ref, router);
      }
    }).catchError((e) {
      debugPrint('Error getInitialLink: $e');
    });

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri, ref, router);
      },
      onError: (e) {
        debugPrint('Error uriLinkStream: $e');
      },
    );
  }

  void _handleUri(Uri uri, WidgetRef ref, GoRouter router) async {
    // Format link: https://kerkom.app/j/{code}
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'j') {
      final code = uri.pathSegments[1].toUpperCase();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Simpan pending code jika user belum login
        ref.read(pendingInviteCodeProvider.notifier).state = code;
        router.go('/login');
      } else {
        // User sudah login, langsung gabung dan buka lobi
        try {
          final roomRepo = ref.read(roomRepositoryProvider);
          final room = await roomRepo.joinRoomByCode(code);
          router.push('/lobby/${room.id}');
        } catch (e) {
          debugPrint('Gagal join room via deep link: $e');
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
});
