import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../room/presentation/room_controller.dart';

class DataInspectorScreen extends ConsumerStatefulWidget {
  const DataInspectorScreen({super.key});

  @override
  ConsumerState<DataInspectorScreen> createState() => _DataInspectorScreenState();
}

class _DataInspectorScreenState extends ConsumerState<DataInspectorScreen> {
  Map<dynamic, dynamic>? _rawSnapshot;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRawData();
  }

  Future<void> _fetchRawData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Pengguna belum terautentikasi (currentUser == null)';
      });
      return;
    }

    try {
      final db = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      final snap = await db.ref('userRooms/${user.uid}').get();
      setState(() {
        _isLoading = false;
        _rawSnapshot = snap.exists && snap.value is Map ? (snap.value as Map) : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug only screen')),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final userRooms = ref.watch(userRoomsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Firebase Data Inspector'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchRawData();
              ref.invalidate(userRoomsStreamProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEBUG DIAGNOSTICS', style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text('UID: ${user?.uid ?? "null"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Email: ${user?.email ?? "-"}'),
                    Text('DisplayName: ${user?.displayName ?? "-"}'),
                    const SizedBox(height: 8),
                    const Text('databaseURL: https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('USER ROOMS INDEX (${userRooms.length})', style: AppTheme.labelSmall.copyWith(color: AppColors.navy)),
                        ElevatedButton(
                          onPressed: () async {
                            final uid = user?.uid;
                            if (uid != null) {
                              final count = await ref.read(roomRepositoryProvider).syncAndMigrateUserRooms(uid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Migrasi selesai! Ditemukan & disinkron: $count ruang')),
                                );
                                _fetchRawData();
                              }
                            }
                          },
                          child: const Text('Run Migration'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (userRooms.isEmpty)
                      const Text('Belum ada data index di stream userRoomsProvider.', style: TextStyle(color: AppColors.textMuted))
                    else
                      ...userRooms.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• [${r.role}] ${r.name} (${r.code}) - status: ${r.status}'),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RAW SNAPSHOT (userRooms/${user?.uid})', style: AppTheme.labelSmall.copyWith(color: AppColors.navy)),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_errorMessage != null)
                      Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))
                    else if (_rawSnapshot == null)
                      const Text('Snapshot kosong (null / belum ada node).', style: TextStyle(color: AppColors.textMuted))
                    else
                      Text(_rawSnapshot.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
