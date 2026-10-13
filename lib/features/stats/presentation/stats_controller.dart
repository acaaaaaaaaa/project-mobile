import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/stats_repository.dart';
import '../domain/stats_model.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

final userStatsStreamProvider = StreamProvider<UserStats>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return Stream.value(const UserStats());
  final repo = ref.watch(statsRepositoryProvider);
  return repo.watchUserStats(uid);
});
