import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';

class S21IntegrasiKalenderScreen extends ConsumerWidget {
  const S21IntegrasiKalenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final settings = user?.settings;
    final isGoogleUser = user?.provider == 'google' || user?.email.endsWith('@gmail.com') == true;

    final isGoogleConnected = settings?.googleCalendarConnected ?? isGoogleUser;
    final isOutlookConnected = settings?.outlookCalendarConnected ?? false;
    final isAutoSync = settings?.autoSyncCalendar ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Integrasi Kalender',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Google Calendar Card
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Calendar',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGoogleConnected ? 'Terhubung' : 'Hubungkan',
                            style: AppTheme.bodySmall.copyWith(
                              color: isGoogleConnected ? const Color(0xFF16A34A) : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isGoogleConnected,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      onChanged: (val) async {
                        try {
                          if (val) {
                            final success = await ref
                                .read(authRepositoryProvider)
                                .requestGoogleCalendarConsent();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Persetujuan Google Calendar berhasil! (${user?.email ?? 'akun aktif'})',
                                  ),
                                  backgroundColor: AppColors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Persetujuan Google Calendar dibatalkan.'),
                                  backgroundColor: AppColors.navy,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            await ref.read(authRepositoryProvider).updateCalendarSettings(
                                  googleCalendarConnected: false,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google Calendar diputuskan.'),
                                  backgroundColor: AppColors.navy,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal menghubungkan Google Calendar: Pastikan SHA-1 terdaftar di Firebase Console.',
                                ),
                                backgroundColor: AppColors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Outlook Calendar Card
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF0284C7),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outlook Calendar',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOutlookConnected ? 'Terhubung' : 'Hubungkan',
                            style: AppTheme.bodySmall.copyWith(
                              color: isOutlookConnected ? const Color(0xFF16A34A) : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOutlookConnected,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      onChanged: (val) async {
                        try {
                          await ref.read(authRepositoryProvider).updateCalendarSettings(
                                outlookCalendarConnected: val,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val
                                    ? 'Outlook Calendar terhubung'
                                    : 'Outlook Calendar diputuskan'),
                                backgroundColor: val ? AppColors.green : AppColors.navy,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Sinkronisasi Otomatis Card
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sinkronisasi Otomatis',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jadwal dari kalender akan ditampilkan di tab Ruang.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: isAutoSync,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      onChanged: (val) async {
                        try {
                          await ref.read(authRepositoryProvider).updateCalendarSettings(
                                autoSyncCalendar: val,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val
                                    ? 'Sinkronisasi otomatis diaktifkan'
                                    : 'Sinkronisasi otomatis dinonaktifkan'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
                            );
                          }
                        }
                      },
                    ),
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
