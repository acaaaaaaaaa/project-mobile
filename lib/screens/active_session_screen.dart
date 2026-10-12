import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../services/sensor_service.dart';
import '../services/room_service.dart';
import '../models/room_model.dart';
import 'incident_screen.dart';
import 'riwayat_log_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final int totalMinutes;
  final String roomTitle;

  const ActiveSessionScreen({
    super.key,
    this.totalMinutes = 45,
    this.roomTitle = 'Kerkom Algoritma Lanjut',
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  final PhoneMotionService _sensorService = PhoneMotionService();
  final RoomService _roomService = RoomService();
  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<bool>? _liftSub;
  StreamSubscription<String>? _roomAlertSub;

  late int _remainingSeconds;
  Timer? _countdownTimer;

  double _pitch = 0.02;
  double _roll = 0.02;
  double _vibration = 0.00;

  // Slide to exit drag offset
  double _sliderOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalMinutes * 60;

    _sensorService.startMonitoring(
      onLifted: (episode) => _handlePhoneLifted(),
    );

    _sensorSub = _sensorService.readingStream.listen((reading) {
      if (mounted) {
        setState(() {
          _pitch = double.parse((reading.x * 0.05).toStringAsFixed(2));
          _roll = double.parse((reading.y * 0.05).toStringAsFixed(2));
          _vibration = double.parse((reading.magnitude * 0.02).clamp(0.0, 2.5).toStringAsFixed(2));
        });
      }
    });

    _liftSub = _sensorService.liftStateStream.listen((isLifted) {
      if (isLifted && mounted) {
        _handlePhoneLifted();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _navigateToSummary();
      }
    });

    _roomAlertSub = _roomService.distractionAlertStream.listen((alertMsg) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alertMsg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _handlePhoneLifted() {
    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const IncidentScreen()),
    );
  }

  void _navigateToSummary() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RiwayatLogScreen()),
    );
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _liftSub?.cancel();
    _roomAlertSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / (widget.totalMinutes * 60);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Sensor Locked Bar
              _buildTopLockedBar(),
              const SizedBox(height: 14),

              // 2. Large Deep Indigo Focus Timer Card
              _buildFocusTimerCard(progress),
              const SizedBox(height: 14),

              // 3. XP Accumulation Banner
              _buildXpAccumulationCard(),
              const SizedBox(height: 16),

              // 4. Kelompok Belajar Aktif (4)
              _buildActiveGroupSection(),
              const SizedBox(height: 18),

              // 5. Prosedur Keluar Sesi (Bebas Penalti)
              _buildExitProcedureCard(),
              const SizedBox(height: 20),

              // Test Simulation Shortcut Button for Android Studio
              _buildEmulatorHelperButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopLockedBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 14),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'SENSOR TERKUNCI: GYRO & ACCELE...',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6EE7B7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTimerCard(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF28256E), Color(0xFF1E1B4B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top pill: Sensitivitas: Stabil
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, color: Color(0xFF6EE7B7), size: 14),
                SizedBox(width: 6),
                Text(
                  'Sensitivitas: Stabil • 0 getaran terdeteksi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Circular Dial Countdown Timer
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                // Glowing Mint Progress Indicator
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                  ),
                ),
                // Center Countdown Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'tersisa dari ${widget.totalMinutes}:00 menit target',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF6EE7B7), size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+15 XP  /  10m',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6EE7B7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3 Telemetry Metrics (PITCH, ROLL, VIBRATION)
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox(
                  label: 'PITCH',
                  value: _pitch >= 0 ? '+${_pitch.toStringAsFixed(2)}°' : '${_pitch.toStringAsFixed(2)}°',
                  valueColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryBox(
                  label: 'ROLL',
                  value: _roll >= 0 ? '+${_roll.toStringAsFixed(2)}°' : '${_roll.toStringAsFixed(2)}°',
                  valueColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryBox(
                  label: 'VIBRATION',
                  value: '${_vibration.toStringAsFixed(2)} G',
                  valueColor: const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpAccumulationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.military_tech_rounded, color: Color(0xFFD97706), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+34 XP Terkumpul',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '+15 Teamwork Bonus menanti di menit 45',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6EE7B7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'SYNC 100%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF064E3B),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGroupSection() {
    return ListenableBuilder(
      listenable: _roomService,
      builder: (context, _) {
        final currentRoom = _roomService.currentRoom;
        final currentUserId = _roomService.currentUser?.id;
        final members = currentRoom?.members;
        final memberCount = members != null && members.isNotEmpty ? members.length : 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_rounded, size: 16, color: Color(0xFF312E81)),
                    const SizedBox(width: 6),
                    Text(
                      'Kelompok Belajar Aktif ($memberCount)',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Sesi Komitmen Fisik',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (members != null && members.isNotEmpty) ...[
              for (final member in members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: () {
                    final isSelf = member.id == currentUserId;
                    final isLifted = member.status == MemberStatus.phoneLifted;
                    return _buildActiveMemberTile(
                      name: member.name + (isSelf ? ' (Anda)' : ''),
                      isSelf: isSelf,
                      subtext: isLifted
                          ? '⚠️ HP Terangkat! (${member.distractionCount}x gangguan)'
                          : isSelf
                              ? 'HP Diam di Meja • ${_pitch.abs().toStringAsFixed(1)}° kemiringan'
                              : 'Stabil di Meja Belajar',
                      statusPill: isLifted
                          ? _buildPill('🚨 Terangkat!', const Color(0xFFFEE2E2), const Color(0xFFB91C1C))
                          : _buildPill('● Aman', const Color(0xFF6EE7B7), const Color(0xFF064E3B)),
                      avatarUrl: member.avatarUrl,
                      initials: member.avatarUrl == null && member.name.isNotEmpty
                          ? member.name.substring(0, 1).toUpperCase()
                          : null,
                      dotColor: isLifted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    );
                  }(),
                ),
            ] else ...[
              _buildActiveMemberTile(
                name: '${_roomService.userName} (Anda)',
                isSelf: true,
                subtext: 'HP Diam di Meja • ${_pitch.abs().toStringAsFixed(1)}° kemiringan',
                statusPill: _buildPill('● Aman', const Color(0xFF6EE7B7), const Color(0xFF064E3B)),
                dotColor: const Color(0xFF10B981),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveMemberTile({
    required String name,
    required String subtext,
    required Widget statusPill,
    String? avatarUrl,
    String? initials,
    required Color dotColor,
    bool isSelf = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          if (initials != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDBEAFE),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Icon(Icons.circle, color: dotColor, size: 9),
                ),
              ],
            )
          else
            AppAvatar(
              name: name,
              imageUrl: avatarUrl,
              size: 40,
              badge: Icon(Icons.circle, color: dotColor, size: 9),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Anda',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          statusPill,
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildExitProcedureCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prosedur Keluar Sesi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'BEBAS  PENALTI',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF047857),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Slide to exit bar
          LayoutBuilder(
            builder: (context, constraints) {
              final maxDrag = constraints.maxWidth - 52;
              return Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Text Hint
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Geser untuk Izin Keluar Normal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.keyboard_double_arrow_right_rounded, size: 16, color: Color(0xFF1E3A8A)),
                        ],
                      ),
                    ),
                    // Draggable Button
                    Positioned(
                      left: _sliderOffset,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _sliderOffset = (_sliderOffset + details.delta.dx).clamp(0.0, maxDrag);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (_sliderOffset > maxDrag * 0.7) {
                            // Completed drag -> Exit safely!
                            _navigateToSummary();
                          } else {
                            // Reset
                            setState(() {
                              _sliderOffset = 0.0;
                            });
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B4B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.exit_to_app_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          const Text(
            'Sentuh perlahan tanpa mengangkat HP jika ada keperluan darurat. Sesi teman Anda akan tetap berlanjut tanpa terganggu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmulatorHelperButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tes Simulasi Gerakan (Android Studio)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          ElevatedButton(
            onPressed: _handlePhoneLifted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Angkat HP', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
