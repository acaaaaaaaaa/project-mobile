import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../services/sensor_service.dart';
import 'beranda_screen.dart';
import 'ruang_sesi_screen.dart';
import 'riwayat_log_screen.dart';
import 'profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final RoomService _roomService = RoomService();

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showCreateRoomDialog() {
    final titleController = TextEditingController(text: 'Kerkom Algoritma Lanjut');
    int selectedDuration = 45;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        'Buat Ruang StudyPact',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Sesi / Mata Kuliah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Durasi Belajar (Menit):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [25, 45, 60, 90].map((dur) {
                      final isSel = selectedDuration == dur;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedDuration = dur;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$dur Mnt',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _roomService.createRoom(
                        leaderName: _roomService.userName,
                        title: titleController.text,
                        durationMinutes: selectedDuration,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _switchTab(1); // Go to Ruang Sesi Lobby
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Buka Ruang & Undang Tim',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showJoinCodeDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Gabung via Kode Ruang',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masukkan kode PIN atau ID ruang belajar rekanmu (contoh: PACT-8821).',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'PACT-xxxx',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (codeController.text.trim().isEmpty) return;
                                    setDialogState(() {
                                      isLoading = true;
                                    });
                                    final success = await _roomService.joinRoom(
                                      memberName: _roomService.userName,
                                      roomCode: codeController.text,
                                    );
                                    if (!success) {
                                      setDialogState(() {
                                        isLoading = false;
                                      });
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Room "${codeController.text.toUpperCase()}" tidak ditemukan di server online!',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _switchTab(1); // Go to Ruang Sesi Lobby
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Gabung Lobi',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      BerandaScreen(
        onOpenLobby: () => _switchTab(1),
        onCreateRoom: _showCreateRoomDialog,
        onJoinCode: _showJoinCodeDialog,
        onOpenHistory: () => _switchTab(2),
        onOpenProfile: () => _switchTab(3),
      ),
      RuangSesiScreen(
        onOpenHistory: () => _switchTab(2),
        onOpenProfile: () => _switchTab(3),
        onCreateRoom: _showCreateRoomDialog,
        onJoinCode: _showJoinCodeDialog,
      ),
      RiwayatLogScreen(
        onBackToHome: () => _switchTab(0),
        onOpenProfile: () => _switchTab(3),
      ),
      ProfilScreen(
        onOpenHistory: () => _switchTab(2),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E293B),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Ruang Sesi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded),
              activeIcon: Icon(Icons.trending_up_rounded),
              label: 'Riwayat & Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  void showSensorDiagnosticDialog(BuildContext context) async {
    final sensorService = PhoneMotionService();
    sensorService.startMonitoring();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StreamBuilder<SensorReading>(
        stream: sensorService.readingStream,
        builder: (ctx, snapshot) {
          final reading = snapshot.data;
          final mag = reading?.magnitude ?? 0.0;
          final isLifted = mag > sensorService.sensitivity.threshold;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  sensorService.stopMonitoring();
                  Navigator.pop(ctx);
                },
                child: const Text('Tutup', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          );
        },
      ),
    );
    sensorService.stopMonitoring();
  }
}
