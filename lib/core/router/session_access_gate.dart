import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/room/presentation/room_controller.dart';
import '../../features/session/presentation/session_controller.dart';

/// Resolve the room before mounting pages that can start sensors or a session.
class SessionAccessGate extends ConsumerStatefulWidget {
  final String roomId;
  final Widget child;

  const SessionAccessGate({
    super.key,
    required this.roomId,
    required this.child,
  });

  @override
  ConsumerState<SessionAccessGate> createState() => _SessionAccessGateState();
}

class _SessionAccessGateState extends ConsumerState<SessionAccessGate> {
  bool _admitted = false;
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    // The mounted page owns live completion, cleanup and history persistence.
    if (_admitted) return widget.child;
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final history = ref.watch(userSessionsProvider);
    if (roomAsync.isLoading || history.isLoading) return _loading();
    final room = roomAsync.valueOrNull;
    final now = ref.read(serverTimeServiceProvider).nowServerMs;
    // Ruang hanya dianggap selesai jika room berstatus 'selesai', waktu habis (expired),
    // atau room sudah dihapus dari database aktif namun ada di riwayat pengguna.
    // Jika sesi masih berjalan (belum habis), pengguna diizinkan masuk kembali.
    final isRoomFinished = room != null && (room.status == 'selesai' || room.hasEndedAt(now));
    final isRoomMissingButInHistory = room == null &&
        (history.valueOrNull?.any((session) => session.roomId == widget.roomId) ?? false);
    final completed = isRoomFinished || isRoomMissingButInHistory;
    if (completed) {
      if (!_redirecting) {
        _redirecting = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.replace('/session-summary/${widget.roomId}?readOnly=true');
          }
        });
      }
      return _loading();
    }
    if (room == null || roomAsync.hasError || history.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ruang belum dapat dibuka.'),
              TextButton(
                onPressed: () {
                  ref.invalidate(roomProvider(widget.roomId));
                  ref.invalidate(userSessionsProvider);
                },
                child: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      );
    }
    _admitted = true;
    return widget.child;
  }

  Widget _loading() =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
