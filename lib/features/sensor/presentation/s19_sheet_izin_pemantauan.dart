import '../../../core/utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';

/// Pilihan izin pemantauan saat layar mati (S19)
enum MonitorPermissionOption {
  always('always', 'Selalu', 'Langsung aktif tiap sesi. Kerkom meminta pengecualian hemat baterai agar tidak dimatikan sistem.', true),
  whileSession('whileSession', 'Saat sesi berjalan', 'Aktif otomatis hanya selama sesi berlangsung.', false),
  once('once', 'Sekali saja', 'Hanya untuk sesi ini, ditanya lagi lain kali.', false);

  final String key;
  final String title;
  final String description;
  final bool isRecommended;

  const MonitorPermissionOption(this.key, this.title, this.description, this.isRecommended);
}

class S19SheetIzinPemantauanScreen extends StatelessWidget {
  const S19SheetIzinPemantauanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pemantauan Layar Mati',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: const S19SheetIzinPemantauanContent(isSheet: false),
        ),
      ),
    );
  }
}

class S19SheetIzinPemantauanContent extends ConsumerStatefulWidget {
  final bool isSheet;
  final VoidCallback? onCompleted;

  const S19SheetIzinPemantauanContent({
    super.key,
    this.isSheet = true,
    this.onCompleted,
  });

  /// Helper untuk membuka S19 sebagai Modal Bottom Sheet
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const S19SheetIzinPemantauanContent(isSheet: true),
    );
  }

  @override
  ConsumerState<S19SheetIzinPemantauanContent> createState() => _S19SheetIzinPemantauanContentState();
}

class _S19SheetIzinPemantauanContentState extends ConsumerState<S19SheetIzinPemantauanContent> {
  MonitorPermissionOption _selected = MonitorPermissionOption.always;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      final perm = user.settings.monitorPermission;
      if (perm == 'whileSession') {
        _selected = MonitorPermissionOption.whileSession;
      } else if (perm == 'once') {
        _selected = MonitorPermissionOption.once;
      } else {
        _selected = MonitorPermissionOption.always;
      }
    }
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    try {
      if (AppPlatform.isAndroid) {
        // 1. Jika memilih 'Selalu', minta pengecualian optimasi baterai sistem
        if (_selected == MonitorPermissionOption.always) {
          final isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
          if (!isIgnoring) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
        }

        // 2. Minta izin notifikasi Android 13+
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // 3. Simpan pilihan di users/{uid}/settings/monitorPermission
      await ref.read(authRepositoryProvider).updateMonitorPermission(_selected.key);

      if (mounted) {
        widget.onCompleted?.call();
        if (widget.isSheet) {
          Navigator.of(context).pop(_selected.key);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengaturan pemantauan disimpan'),
              backgroundColor: AppColors.green,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeny() async {
    setState(() => _isLoading = true);
    try {
      // Simpan status 'denied' agar sesi menggunakan fallback layar menyala (wakelock_plus)
      await ref.read(authRepositoryProvider).updateMonitorPermission('denied');

      if (mounted) {
        widget.onCompleted?.call();
        if (widget.isSheet) {
          Navigator.of(context).pop('denied');
        } else {
          context.pop();
        }
      }
    } catch (_) {
      if (mounted) {
        if (widget.isSheet) Navigator.of(context).pop('denied');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: widget.isSheet ? 12.0 : 0.0,
        bottom: 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle jika berupa sheet
          if (widget.isSheet) ...[
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Badge & Header
          Row(
            children: [
              const Icon(Icons.screen_lock_portrait, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'IZIN LATAR BELAKANG',
                style: AppTheme.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pantau sesi saat layar mati?',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kerkom perlu tetap berjalan di latar belakang supaya HP yang terangkat tetap terdeteksi saat layar mati. Notifikasi sesi tampil selama sesi berlangsung.',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Radio options
          ...MonitorPermissionOption.values.map((option) {
            final isSelected = _selected == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _selected = option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceContainer : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Radio circle indicator
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check, size: 14, color: AppColors.background),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  option.title,
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (option.isRecommended) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Direkomendasikan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Tombol Lanjutkan
          PrimaryButton(
            text: 'Lanjutkan',
            isLoading: _isLoading,
            onPressed: _handleConfirm,
          ),
          const SizedBox(height: 8),

          // Tombol Jangan Izinkan (Fallback Layar Menyala)
          TextButton(
            onPressed: _isLoading ? null : _handleDeny,
            child: Column(
              children: [
                Text(
                  'Jangan izinkan',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sesi membutuhkan layar tetap menyala',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
