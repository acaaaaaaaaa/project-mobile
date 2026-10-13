import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../session/presentation/session_controller.dart';

class S17PengaturanAlarmScreen extends ConsumerStatefulWidget {
  const S17PengaturanAlarmScreen({super.key});

  @override
  ConsumerState<S17PengaturanAlarmScreen> createState() => _S17PengaturanAlarmScreenState();
}

class _S17PengaturanAlarmScreenState extends ConsumerState<S17PengaturanAlarmScreen> {
  String _alarmMode = 'both';
  double _volume = 0.8;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isTestingAlarm = false;

  @override
  void dispose() {
    ref.read(alarmServiceProvider).stop();
    super.dispose();
  }

  void _toggleTestAlarm() {
    final alarmService = ref.read(alarmServiceProvider);
    if (_isTestingAlarm) {
      alarmService.stop();
      setState(() => _isTestingAlarm = false);
    } else {
      setState(() => _isTestingAlarm = true);
      alarmService.triggerAlarm(alarmMode: _alarmMode, volume: _volume);
      // Sinkronkan state jika alarm berhenti otomatis setelah 10s
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isTestingAlarm) {
          setState(() => _isTestingAlarm = false);
        }
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      ref.read(alarmServiceProvider).stop();
      setState(() => _isTestingAlarm = false);

      await ref.read(authRepositoryProvider).updateAlarmSettings(
            alarmMode: _alarmMode,
            volume: _volume,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan alarm berhasil disimpan!'),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      final user = ref.watch(currentUserProvider).value;
      if (user != null) {
        _alarmMode = user.settings.alarmMode;
        _volume = user.settings.volume;
        _isInitialized = true;
      }
    }

    final isVibrateOnly = _alarmMode == 'vibrate';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            ref.read(alarmServiceProvider).stop();
            context.pop();
          },
        ),
        title: Text(
          'Pengaturan Alarm',
          style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Local Device Preference Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.devices_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textPrimary),
                          children: const [
                            TextSpan(
                              text: 'Preferensi Lokal: ',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            TextSpan(
                              text: 'Berlaku di HP-mu saja, tidak memengaruhi rekan kelompok.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Section
              Text(
                'TIPE NOTIFIKASI GERAK',
                style: AppTheme.labelSmall.copyWith(
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              // Mode 1: Audio
              _buildModeCard(
                mode: 'audio',
                title: 'Audio',
                desc: 'Hanya suara dering peringatan saat HP terangkat',
                icon: Icons.volume_up_rounded,
              ),
              const SizedBox(height: 10),

              // Mode 2: Getar
              _buildModeCard(
                mode: 'vibrate',
                title: 'Getar',
                desc: 'Hanya getaran haptik tegas tanpa suara dering',
                icon: Icons.vibration_rounded,
              ),
              const SizedBox(height: 10),

              // Mode 3: Audio dan Getar
              _buildModeCard(
                mode: 'both',
                title: 'Audio dan Getar',
                desc: 'Kombinasi suara dering dan getaran maksimal',
                icon: Icons.notifications_active_rounded,
              ),
              const SizedBox(height: 20),

              // Volume Slider Module
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isVibrateOnly ? 0.4 : 1.0,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.volume_down_rounded, size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Volume Alarm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(_volume * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceContainer,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: isVibrateOnly
                              ? null
                              : (val) {
                                  setState(() => _volume = val);
                                },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVibrateOnly
                            ? 'Volume tidak aktif untuk mode Hanya Getar.'
                            : 'Tingkat volume ini akan mengabaikan mode Senyap jika alarm darurat terpicu.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Test Alarm Action Button
              AppCard(
                onTap: _toggleTestAlarm,
                backgroundColor: _isTestingAlarm
                    ? AppColors.red.withValues(alpha: 0.12)
                    : AppColors.card,
                border: Border.all(
                  color: _isTestingAlarm ? AppColors.red : AppColors.cardBorder,
                  width: 1.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isTestingAlarm ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                      color: _isTestingAlarm ? AppColors.red : AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isTestingAlarm ? 'Hentikan Tes Alarm' : 'Tes Alarm HP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _isTestingAlarm ? AppColors.red : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save CTA Button
              PrimaryButton(
                text: 'Simpan',
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 10),
              const Text(
                'Perubahan akan otomatis diterapkan pada sesi kerja kelompok berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _alarmMode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _alarmMode = mode);
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
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
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
          ],
        ),
      ),
    );
  }
}
