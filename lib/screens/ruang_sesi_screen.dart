import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/studypact_app_bar.dart';
import '../widgets/app_avatar.dart';
import '../services/sensor_service.dart';
import '../services/room_service.dart';
import '../models/room_model.dart';
import 'incident_screen.dart';
import 'late_joiner_screen.dart';
import 'riwayat_log_screen.dart';
import 'active_session_screen.dart';

class RuangSesiScreen extends StatefulWidget {
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;
  final VoidCallback? onCreateRoom;
  final VoidCallback? onJoinCode;

  const RuangSesiScreen({
    super.key,
    required this.onOpenHistory,
    required this.onOpenProfile,
    this.onCreateRoom,
    this.onJoinCode,
  });

  @override
  State<RuangSesiScreen> createState() => _RuangSesiScreenState();
}

class _RuangSesiScreenState extends State<RuangSesiScreen> {
  final PhoneMotionService _sensorService = PhoneMotionService();
  final RoomService _roomService = RoomService();
  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<String>? _alertSub;
  double _sensorX = 0.2;
  double _sensorY = 0.1;
  bool _travelModeEnabled = false;
  int _calibrationCountdown = 3;
  bool _isNavigatingToSession = false;

  @override
  void initState() {
    super.initState();
    _sensorService.startMonitoring();
    _sensorSub = _sensorService.readingStream.listen((reading) {
      if (mounted) {
        setState(() {
          _sensorX = double.parse((reading.x * 0.1).toStringAsFixed(1));
          _sensorY = double.parse((reading.y * 0.1).toStringAsFixed(1));
        });
      }
    });

    _roomService.addListener(_onRoomServiceChanged);

    _alertSub = _roomService.distractionAlertStream.listen((msg) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _onRoomServiceChanged() {
    if (!mounted) return;
    final room = _roomService.currentRoom;
    if (room != null && room.isSessionActive && !_isNavigatingToSession) {
      _isNavigatingToSession = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveSessionScreen(
            totalMinutes: room.durationMinutes,
            roomTitle: room.title,
          ),
        ),
      ).then((_) {
        _isNavigatingToSession = false;
      });
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _alertSub?.cancel();
    _roomService.removeListener(_onRoomServiceChanged);
    super.dispose();
  }

  void _startCalibrationDialog() {
    setState(() {
      _calibrationCountdown = 3;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_calibrationCountdown > 1) {
                if (ctx.mounted) {
                  setDialogState(() {
                    _calibrationCountdown--;
                  });
                }
              } else {
                timer.cancel();
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  _showSessionStartedSnackbar();
                  final room = RoomService().currentRoom;
                  RoomService().startSession();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveSessionScreen(
                        totalMinutes: room?.durationMinutes ?? 45,
                        roomTitle: room?.title ?? 'Kerkom Algoritma Lanjut',
                      ),
                    ),
                  );
                }
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDCFCE7),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          '$_calibrationCountdown',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mengalibrasi Sensor Meja...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Letakkan HP dengan tenang di meja. Titik sudut 0° sedang disinkronkan ke seluruh tim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSessionStartedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('Sesi Fokus Aktif! Semua sensor ponsel tim terkunci.')),
          ],
        ),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _roomService,
          builder: (context, _) {
            final currentRoom = _roomService.currentRoom;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudyPactAppBar(
                    subtitle: 'Ruang Sesi',
                    onProfileTap: widget.onOpenProfile,
                    onStreakTap: widget.onOpenHistory,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: currentRoom == null
                        ? _buildNoRoomState(context)
                        : _buildActiveRoomView(context, currentRoom),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoRoomState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFECFDF5),
                ),
                child: const Icon(Icons.meeting_room_outlined, color: Color(0xFF047857), size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Ruang Aktif',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buka ruang baru sebagai Host atau masukkan kode PACT untuk belajar fokus bersama rekan Anda secara online.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onCreateRoom,
                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      label: const Text('Buat Ruang', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onJoinCode,
                      icon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF0284C7)),
                      label: const Text('Gabung Kode', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        backgroundColor: const Color(0xFFF0F9FF),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSensorInspectionSection(),
        const SizedBox(height: 20),
        _buildDemoShortcuts(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActiveRoomView(BuildContext context, StudyRoom currentRoom) {
    final currentUserId = _roomService.currentUser?.id;
    final isHost = currentRoom.leaderId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Badges Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: currentRoom.isSessionActive ? const Color(0xFFFEF3C7) : const Color(0xFF6EE7B7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: currentRoom.isSessionActive ? const Color(0xFFD97706) : const Color(0xFF065F46),
                    size: 7,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    currentRoom.isSessionActive ? 'SESI SEDANG BERJALAN' : 'LOBI AKTIF • ONLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: currentRoom.isSessionActive ? const Color(0xFF92400E) : const Color(0xFF064E3B),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Host: ${currentRoom.leaderName}${isHost ? ' (Anda)' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Room Title
        Text(
          currentRoom.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Kode: ${currentRoom.code} • Durasi Target: ${currentRoom.durationMinutes} Menit',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 16),

        // Room Code Card
        _buildRoomCodeCard(context, currentRoom),
        const SizedBox(height: 20),

        // Anggota Terkoneksi (Real-time Firebase)
        _buildConnectedMembersSection(context, currentRoom),
        const SizedBox(height: 20),

        // Pemeriksaan Sensor Ponsel
        _buildSensorInspectionSection(),
        const SizedBox(height: 22),

        // Action Buttons (CTA)
        _buildActionButtons(context),
        const SizedBox(height: 24),

        // Demo / Showcase Navigation Card
        _buildDemoShortcuts(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRoomCodeCard(BuildContext context, StudyRoom currentRoom) {
    final roomCode = currentRoom.code;
    final durationMinutes = currentRoom.durationMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KODE RUANG PACT (BAGIKAN KE TEMAN)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      roomCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: roomCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kode ruang ($roomCode) disalin ke clipboard!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 12, color: Color(0xFF4F46E5)),
                            SizedBox(width: 4),
                            Text(
                              'Salin',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1E1B4B)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$durationMinutes Menit',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const Text(
                          'Standar Sesi',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pergerakan sensor ponsel setiap peserta tersinkronisasi otomatis via Firebase.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedMembersSection(BuildContext context, StudyRoom currentRoom) {
    final currentUserId = _roomService.currentUser?.id;
    final members = currentRoom.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.group_outlined, size: 18, color: Color(0xFF312E81)),
                SizedBox(width: 8),
                Text(
                  'Anggota Terkoneksi (Real-time)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${members.length} Peserta Aktif',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Members List from Firebase
        for (final member in members) ...[
          () {
            final isSelf = member.id == currentUserId;
            final isLifted = member.status == MemberStatus.phoneLifted;
            final statusText = isLifted
                ? '🚨 HP Terangkat! (${member.distractionCount}x gangguan)'
                : isSelf
                    ? '● Siap di Meja • Tilt $_sensorX°'
                    : '● Siap di Meja Belajar';
            final statusColor = isLifted ? const Color(0xFFEF4444) : const Color(0xFF10B981);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildMemberCard(
                name: member.name,
                isSelf: isSelf,
                status: statusText,
                statusColor: statusColor,
                imageUrl: member.avatarUrl,
                badgeWidget: _buildTag(
                  icon: member.isLeader ? Icons.star_rounded : Icons.person_rounded,
                  label: member.isLeader ? 'Host' : 'Peserta',
                  bg: member.isLeader ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                  textColor: member.isLeader ? const Color(0xFF15803D) : const Color(0xFF4F46E5),
                ),
              ),
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildMemberCard({
    required String name,
    required String status,
    required Color statusColor,
    required Widget badgeWidget,
    String? imageUrl,
    bool isSelf = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(
            name: name,
            imageUrl: imageUrl,
            size: 40,
            badge: Icon(Icons.check_circle, color: statusColor, size: 12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          badgeWidget,
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInspectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.sensors_rounded, size: 18, color: Color(0xFF312E81)),
                SizedBox(width: 8),
                Text(
                  'Pemeriksaan Sensor Ponsel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6EE7B7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '3/3 Lolos',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF064E3B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Check 1: Mode Perjalanan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_subway_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Mode Perjalanan (Travel Mode)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🚆 / 🚗', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Abaikan getaran akselerometer & bumping kendaraan; kunci toleransi kemiringan gyro <30°.',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted, height: 1.25),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _travelModeEnabled,
                  activeThumbColor: const Color(0xFF0284C7),
                  onChanged: (val) {
                    setState(() {
                      _travelModeEnabled = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Check 2: DND
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_off_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Jangan Ganggu (DND) / Senyap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Otomatis dibisukan agar dengung getar pesan WA tidak memicu peringatan gerakan palsu.',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted, height: 1.25),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Check 3: Peletakan di bidang datar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stay_current_landscape_rounded, color: Color(0xFF047857), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peletakan HP di Bidang Datar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kalibrasi sudut 0° akan dimulai otomatis saat hitungan mundur 3 detik berjalan.',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted, height: 1.25),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Terdeteksi',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Real-time Sensor Readout Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.screen_rotation_rounded, color: Color(0xFF0284C7), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                    children: [
                      const TextSpan(
                        text: 'Sensor Kemiringan Real-time:  ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: 'X: $_sensorX°  |  Y: $_sensorY° (Stabil)',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0C4A6E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Green Button
        ElevatedButton(
          onPressed: _startCalibrationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 3,
            shadowColor: const Color(0xFF047857).withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Mulai Kalibrasi 3 Detik Bersama',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6EE7B7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '4/4 Siap',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF064E3B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Light Button
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID Ruang PACT-7492 dibagikan!')),
            );
          },
          icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF4F46E5)),
          label: const Text(
            'Undang Teman Lain (ID / Link)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4F46E5),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoShortcuts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'Shortcut Tampilan Desain (Android Studio Demo)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncidentScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('🚨 Layar Insiden', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LateJoinerScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('⏳ Bergabung Late', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RiwayatLogScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF047857),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('🏆 Riwayat Sesi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                );
              },
              icon: const Icon(Icons.timer_rounded, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('⏱️ Layar Sesi Berjalan (Live Timer & Sensor)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                backgroundColor: const Color(0xFFEEF2FF),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
