import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/primary_button.dart';
import 'session_controller.dart';

class S11AlarmAnggotaLainScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String violatorName;

  const S11AlarmAnggotaLainScreen({
    super.key,
    required this.roomId,
    required this.violatorName,
  });

  @override
  ConsumerState<S11AlarmAnggotaLainScreen> createState() => _S11AlarmAnggotaLainScreenState();
}

class _S11AlarmAnggotaLainScreenState extends ConsumerState<S11AlarmAnggotaLainScreen> {
  @override
  void dispose() {
    ref.read(alarmServiceProvider).stop();
    super.dispose();
  }

  void _onDismiss() {
    ref.read(alarmServiceProvider).stop();
    // 5. S11 'Tutup Peringatan' -> S09
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/active-session/${widget.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B0A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Alert Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.red),
                        SizedBox(width: 6),
                        Text(
                          'ALARM KELOMPOK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Timer Tetap Berjalan',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),

              // Central Violator Beacon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: AvatarCircle(
                        name: widget.violatorName,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    '${widget.violatorName}\nmengangkat HP!',
                    style: AppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alarm berbunyi di semua perangkat kelompok.\nTetap fokus, timer sesi kelompok tidak berhenti.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Bottom Dismiss CTA
              Column(
                children: [
                  PrimaryButton(
                    text: 'Tutup Peringatan',
                    onPressed: _onDismiss,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Peringatan ini akan berhenti berbunyi otomatis dalam 10 detik.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
