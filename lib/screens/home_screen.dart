import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../services/sensor_service.dart';
import 'study_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RoomService _roomService = RoomService();
  final PhoneMotionService _sensorService = PhoneMotionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // App Branding & Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.screen_lock_portrait_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'FocusRoom',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Mobile & Wireless Computing Study Group',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.cyan.shade200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Concept Explanation Card (Untuk bahan matakuliah)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded, color: Colors.indigoAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bagaimana Cara Kerjanya?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1. Leader membuat room & bagikan kode ke teman.\n'
                            '2. Letakkan HP di atas meja selama sesi belajar.\n'
                            '3. Sensor gerak akan mendeteksi jika HP diangkat dan memberi sinyal broadcast ke seluruh anggota!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              // 1. Buat Room (Leader)
              _buildActionButton(
                context: context,
                title: 'Buat Ruang Belajar Baru',
                subtitle: 'Sebagai Leader: atur durasi dan bagikan kode room',
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF4F46E5),
                onTap: () => _showCreateRoomSheet(context),
              ),
              const SizedBox(height: 16),

              // 2. Gabung Room (Member)
              _buildActionButton(
                context: context,
                title: 'Gabung Ruang Belajar',
                subtitle: 'Masukkan kode room yang dibagikan oleh leader',
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFF0D9488),
                onTap: () => _showJoinRoomSheet(context),
              ),
              const SizedBox(height: 16),

              // 3. Sensor Sandbox / Diagnostic
              _buildActionButton(
                context: context,
                title: 'Uji Sensor HP (Sandbox)',
                subtitle: 'Cek accelerometer perangkat Anda sebelum mulai',
                icon: Icons.tune_rounded,
                color: const Color(0xFF334155),
                onTap: () => _showSensorDiagnosticDialog(context),
              ),
              const SizedBox(height: 32),

              // Footer Credit
              Center(
                child: Text(
                  'Mata Kuliah: Mobile and Wireless Computing\nKelompok Project Mobile Focus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color == const Color(0xFF334155) ? Colors.cyanAccent : color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _showCreateRoomSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Ketua Kelompok');
    final titleCtrl = TextEditingController(text: 'Kerja Kelompok Mobile Computing');
    int selectedDuration = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buat Room Belajar Baru',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nama Anda (Leader)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.indigoAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Judul Sesi / Mata Kuliah',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.menu_book_rounded, color: Colors.indigoAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Durasi Sesi Belajar:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [20, 30, 45, 60].map((duration) {
                    final isSelected = selectedDuration == duration;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text('$duration m'),
                          selected: isSelected,
                          selectedColor: Colors.indigoAccent,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: const Color(0xFF0F172A),
                          onSelected: (val) {
                            setSheetState(() => selectedDuration = duration);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final leaderName = nameCtrl.text.trim().isEmpty ? 'Leader' : nameCtrl.text.trim();
                    final title = titleCtrl.text.trim().isEmpty ? 'Sesi Belajar' : titleCtrl.text.trim();

                    _roomService.createRoom(
                      leaderName: leaderName,
                      title: title,
                      durationMinutes: selectedDuration,
                    );

                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudyRoomScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mulai & Masuk ke Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showJoinRoomSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Nama Saya');
    final codeCtrl = TextEditingController(text: 'ROOM-');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gabung ke Room Teman',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nama Anda',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.tealAccent),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Kode Room (contoh: ROOM-1234)',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.key_rounded, color: Colors.tealAccent),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final memberName = nameCtrl.text.trim().isEmpty ? 'Anggota' : nameCtrl.text.trim();
                final roomCode = codeCtrl.text.trim().isEmpty ? 'ROOM-1000' : codeCtrl.text.trim();

                _roomService.joinRoom(
                  memberName: memberName,
                  roomCode: roomCode,
                );

                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudyRoomScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Gabung Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorDiagnosticDialog(BuildContext context) {
    _sensorService.startMonitoring();

    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<SensorReading>(
        stream: _sensorService.readingStream,
        builder: (ctx, snapshot) {
          final reading = snapshot.data;
          final mag = reading?.magnitude ?? 0.0;
          final isLifted = mag > _sensorService.sensitivity.threshold;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Row(
              children: [
                Icon(Icons.sensors_rounded, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text('Uji Responsivitas Sensor', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLifted ? 'STATUS: TERANGKAT / BERGERAK' : 'STATUS: MEJA (DIAM)',
                  style: TextStyle(
                    color: isLifted ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Akselerasi Saat Ini: ${mag.toStringAsFixed(2)} m/s²',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (mag / 8.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.black38,
                    color: isLifted ? Colors.redAccent : Colors.greenAccent,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Letakkan HP mendatar di meja, lalu coba angkat dengan tangan. Nilai akselerasi akan melonjak mendeteksi pergerakan.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _sensorService.stopMonitoring();
                  Navigator.pop(ctx);
                },
                child: const Text('Tutup', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          );
        },
      ),
    );
  }
}
