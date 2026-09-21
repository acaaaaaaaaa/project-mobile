import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import '../services/sensor_service.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> with SingleTickerProviderStateMixin {
  final RoomService _roomService = RoomService();
  final PhoneMotionService _sensorService = PhoneMotionService();

  StreamSubscription<String>? _alertSubscription;
  StreamSubscription<SensorReading>? _sensorSubscription;
  SensorReading? _latestReading;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Langsung aktifkan sesi saat masuk room jika belum aktif
    if (!_roomService.isSessionRunning) {
      _roomService.startSession();
    }

    _sensorSubscription = _sensorService.readingStream.listen((reading) {
      if (mounted) {
        setState(() {
          _latestReading = reading;
        });
      }
    });

    _alertSubscription = _roomService.distractionAlertStream.listen((message) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _alertSubscription?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _roomService,
      builder: (context, _) {
        final room = _roomService.currentRoom;
        final currentUser = _roomService.currentUser;

        if (room == null || currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('Tidak ada sesi room aktif')),
          );
        }

        final isMyPhoneLifted = _sensorService.isPhoneLifted;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Slate 900
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B), // Slate 800
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Kode Room: ${room.code}',
                  style: TextStyle(fontSize: 12, color: Colors.cyan.shade300),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.cyanAccent),
                tooltip: 'Bagikan Kode Room',
                onPressed: () => _roomService.shareRoomInvitation(),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                tooltip: 'Keluar Room',
                onPressed: () => _confirmExit(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timer & Session Header
                  _buildTimerSection(),
                  const SizedBox(height: 16),

                  // My Status Indicator Card (Status HP Tergeletak vs Terangkat)
                  _buildMyStatusCard(currentUser, isMyPhoneLifted),
                  const SizedBox(height: 16),

                  // Live Sensor Monitor Card (Mobile Computing Hardware Interface)
                  _buildSensorDataCard(),
                  const SizedBox(height: 20),

                  // Header Anggota Kelompok
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, color: Colors.indigoAccent, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Anggota Room (${room.members.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Sync',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Member List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: room.members.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = room.members[index];
                      final isMe = member.id == currentUser.id;
                      return _buildMemberCard(member, isMe: isMe);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Simulation Controls for Testing/Presentation
                  _buildTestingHelperCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SISA WAKTU FOKUS KELOMPOK',
            style: TextStyle(
              color: Colors.indigoAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _roomService.formattedTimer,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _roomService.isSessionRunning ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded,
                color: _roomService.isSessionRunning ? Colors.greenAccent : Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _roomService.isSessionRunning ? 'Sesi Aktif - Sensor Memantau' : 'Sesi Dijeda',
                style: TextStyle(
                  color: _roomService.isSessionRunning ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusCard(Member currentUser, bool isLifted) {
    final statusColor = isLifted ? Colors.redAccent : Colors.greenAccent;
    final statusBg = isLifted ? const Color(0xFF450A0A) : const Color(0xFF064E3B);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLifted ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor, width: isLifted ? 2 : 1),
              boxShadow: isLifted
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLifted ? Icons.phone_android_rounded : Icons.table_restaurant_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isLifted ? 'HP TERANGKAT!' : 'HP DI MEJA (AMAN)',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Distraksi: ${currentUser.distractionCount}x',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLifted
                            ? 'Peringatan terkirim ke teman kelompok! Letakkan kembali HP Anda di meja.'
                            : 'Bagus! Pertahankan fokus Anda dan jangan gunakan HP selama sesi.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorDataCard() {
    final mag = _latestReading?.magnitude ?? 0.0;
    final x = _latestReading?.x ?? 0.0;
    final y = _latestReading?.y ?? 0.0;
    final z = _latestReading?.z ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Komputasi Sensor (Accelerometer Telemetri)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'Thresh: ${_sensorService.sensitivity.threshold} m/s²',
                style: const TextStyle(color: Colors.cyan, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAxisChip('X (Sumbu Horisontal)', x, Colors.blueAccent),
              const SizedBox(width: 8),
              _buildAxisChip('Y (Sumbu Vertikal)', y, Colors.tealAccent),
              const SizedBox(width: 8),
              _buildAxisChip('Z (Sumbu Kedalaman)', z, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (mag / 8.0).clamp(0.0, 1.0),
              backgroundColor: Colors.black26,
              color: mag > _sensorService.sensitivity.threshold ? Colors.redAccent : Colors.cyanAccent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Akselerasi Gerak: ${mag.toStringAsFixed(2)} m/s²',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              GestureDetector(
                onTap: () {
                  _sensorService.calibrateBaseline(mag);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sensor berhasil dikalibrasi ke posisi meja saat ini!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Kalibrasi Meja',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisChip(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label[0], // X, Y, or Z
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              val.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Member member, {required bool isMe}) {
    final isLifted = member.status == MemberStatus.phoneLifted;
    final statusColor = isLifted ? Colors.redAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLifted ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.07),
          width: isLifted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isMe ? Colors.indigoAccent : Colors.blueGrey.shade700,
            radius: 18,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name + (isMe ? ' (Anda)' : ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LEADER',
                          style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLifted ? 'HP Terangkat!' : 'Sedang Fokus',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (member.distractionCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${member.distractionCount}x angkat HP)',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isLifted ? Icons.phone_locked_rounded : Icons.check_circle_outline_rounded,
            color: statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTestingHelperCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_rounded, color: Colors.purpleAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Mode Demo / Pengujian Tanpa Sensor Fisik',
                style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Jika menguji di Android Studio Emulator atau laptop, gunakan tombol di bawah untuk menyimulasikan event HP diangkat.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              _roomService.triggerManualLiftSimulation();
            },
            icon: const Icon(Icons.touch_app_rounded, size: 18),
            label: Text(
              _sensorService.isPhoneLifted ? 'Simulasi: Letakkan HP di Meja' : 'Simulasi: Angkat HP Sekarang',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sensorService.isPhoneLifted ? Colors.green.shade800 : Colors.red.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Keluar dari Sesi Room?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sesi pemantauan fokus Anda akan dihentikan jika Anda meninggalkan room.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              _roomService.leaveRoom();
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close room screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
