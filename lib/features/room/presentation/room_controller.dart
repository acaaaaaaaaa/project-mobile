import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/room_repository.dart';
import '../domain/room_models.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

/// Pending invite code dari deep link ketika user belum login
final pendingInviteCodeProvider = StateProvider<String?>((ref) => null);

/// Stream detail room berdasarkan roomId
final activeRoomProvider = StreamProvider.autoDispose.family<RoomModel?, String>((ref, roomId) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRoom(roomId);
});

final roomProvider = activeRoomProvider;

/// Stream daftar anggota room berdasarkan roomId
final roomMembersProvider = StreamProvider.autoDispose.family<List<RoomMemberModel>, String>((ref, roomId) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRoomMembers(roomId);
});

/// Stream banner room aktif milik user saat ini (untuk S04)
final userActiveRoomBannerProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return Stream.value(null);
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchUserActiveRoom(uid);
});

/// Stream 3 sesi terakhir milik user saat ini (untuk S04)
final userRecentSessionsProvider = StreamProvider<List<UserSessionHistory>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return Stream.value([]);
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRecentSessions(uid);
});

/// Stream seluruh room aktif (untuk Tab Daftar Ruang)
final allRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchAllRooms();
});

/// Stream seluruh ruangan milik user aktif (Host atau Member) dari node userRooms/{uid}
final userRoomsStreamProvider = StreamProvider<List<UserRoomIndex>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return Stream.value(<UserRoomIndex>[]);
  final repo = ref.watch(roomRepositoryProvider);
  // Jalankan migrasi idempotent jika ada room lama yang belum terindeks
  repo.syncAndMigrateUserRooms(uid);
  return repo.watchUserRooms(uid);
});

