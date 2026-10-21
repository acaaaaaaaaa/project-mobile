import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/room_models.dart';
import '../../profile/presentation/notification_controller.dart';
import 'room_controller.dart';
import 's05_sheet_buat_ruang.dart';

class S20DaftarRuangScreen extends ConsumerStatefulWidget {
  const S20DaftarRuangScreen({super.key});

  @override
  ConsumerState<S20DaftarRuangScreen> createState() => _S20DaftarRuangScreenState();
}

class _S20DaftarRuangScreenState extends ConsumerState<S20DaftarRuangScreen> {
  // 0: Kalender, 1: Daftar Ruang
  int _selectedTab = 0;

  late DateTime _currentMonth;
  late int _selectedDay;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter chips untuk Tab Daftar Ruang
  String _selectedFilter = 'Semua';
  DateTime? _customFilterDate;
  bool _sortAscending = true; // true: Terdekat dulu, false: Terjauh dulu

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = now.day;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _getMonthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final userRoomsAsync = ref.watch(userRoomsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar: Logo KerKom dan Icon Notifikasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/kerkom_logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'KerKom',
                        style: AppTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 22),
                          if (ref.watch(hasUnreadNotificationsProvider)) Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Judul Ruang & Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruang',
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pill Tabs: Kalender vs Daftar Ruang
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Kalender',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Daftar Ruang',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildKalenderTab(userRoomsAsync)
                  : _buildDaftarRuangTab(userRoomsAsync),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TAB 1: KALENDER =====================
  Widget _buildKalenderTab(AsyncValue<List<UserRoomIndex>> userRoomsAsync) {
    final rooms = userRoomsAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Monthly Calendar Card
          AppCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: Column(
              children: [
                // Month Header with Nav Arrows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.navy),
                          onPressed: _previousMonth,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Days of week header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                      .map((d) => SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(
                                d,
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Calendar Grid with real indicator dots
                _buildCalendarDaysGrid(rooms),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header Hari Terpilih & Tombol Buat Ruang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedDay ${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final targetDate = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    _selectedDay,
                  );
                  BottomSheetHelper.show(
                    context: context,
                    child: S05SheetBuatRuang(initialDate: targetDate),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text('Buat Ruang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timeline Kegiatan Hari Terpilih dari Firebase RTDB Real
          _buildTimelineSchedules(rooms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCalendarDaysGrid(List<UserRoomIndex> rooms) {
    // Dynamic dots from real user rooms
    final daysWithDots = <int>{};
    for (final r in rooms) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.scheduledStart);
      if (date.year == _currentMonth.year && date.month == _currentMonth.month) {
        daysWithDots.add(date.day);
      }
    }

    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final totalDays = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final gridCells = <Widget>[];

    // Previous month placeholders
    final prevMonthTotalDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      gridCells.add(
        Center(
          child: Text(
            '${prevMonthTotalDays - i}',
            style: AppTheme.bodySmall.copyWith(color: const Color(0xFFCBD5E1)),
          ),
        ),
      );
    }

    // Days in current month
    for (int day = 1; day <= totalDays; day++) {
      final isSelected = day == _selectedDay;
      final hasDot = daysWithDots.contains(day);

      gridCells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (hasDot && !isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: gridCells,
    );
  }

  Widget _buildTimelineSchedules(List<UserRoomIndex> rooms) {
    // Filter ruangan real berdasarkan tanggal terpilih
    final dayRooms = rooms.where((r) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.scheduledStart);
      return d.year == _currentMonth.year &&
          d.month == _currentMonth.month &&
          d.day == _selectedDay;
    }).toList();

    if (dayRooms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_busy_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Belum ada ruangan di tanggal ini',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih tanggal lain atau buat ruangan baru untuk jadwal ini.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Urutkan berdasarkan waktu mulai
    dayRooms.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    return Column(
      children: dayRooms.map((room) {
        final date = DateTime.fromMillisecondsSinceEpoch(room.scheduledStart);
        final endDate = date.add(Duration(minutes: room.durationMin));
        final slot = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        final endSlot = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
        final timeRange = '$slot - $endSlot';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waktu slot di sisi kiri
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Text(
                    slot,
                    style: AppTheme.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Kartu kegiatan
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 16,
                  onTap: () => _navigateToRoom(room),
                  child: Row(
                    children: [
                      // Garis aksen warna
                      Container(
                        width: 4,
                        height: 38,
                        decoration: BoxDecoration(
                          color: room.isHost ? const Color(0xFFD97706) : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info ruang
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  timeRange,
                                  style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: room.isHost ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    room.isHost ? 'Host' : 'Anggota',
                                    style: TextStyle(
                                      color: room.isHost ? const Color(0xFFB45309) : AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Three dots menu button
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => _showRoomActionMenu(context, room),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===================== TAB 2: DAFTAR RUANG =====================
  Widget _buildDaftarRuangTab(AsyncValue<List<UserRoomIndex>> userRoomsAsync) {
    return Column(
      children: [
        // Search Bar & Sort Toggle Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.navy),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      hintText: 'Cari judul ruang atau kode...',
                      hintStyle: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Sort toggle: Terdekat dulu vs Terjauh dulu
              InkWell(
                onTap: () {
                  setState(() => _sortAscending = !_sortAscending);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(_sortAscending ? 'Urutan: Terdekat dulu' : 'Urutan: Terjauh dulu'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  ),
                  child: Icon(
                    _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: AppColors.navy,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Chips Horizontal Scroll
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                'Semua',
                'Hari ini',
                '3 hari ke depan',
                '7 hari ke depan',
                'Minggu ini',
                'Bulan ini',
                'Pilih tanggal',
              ].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      filter == 'Pilih tanggal' && _customFilterDate != null
                          ? '${_customFilterDate!.day} ${_getMonthName(_customFilterDate!.month)}'
                          : filter,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.navy,
                    ),
                    onSelected: (val) async {
                      if (filter == 'Pilih tanggal') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _customFilterDate ?? DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedFilter = 'Pilih tanggal';
                            _customFilterDate = picked;
                          });
                        }
                      } else {
                        setState(() {
                          _selectedFilter = filter;
                          _customFilterDate = null;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // List Daftar Ruang Real
        Expanded(
          child: userRoomsAsync.when(
            data: (rooms) {
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final todayEnd = todayStart.add(const Duration(days: 1));

              // 1. Filter Hanya Ruang Aktif / Belum Selesai (ruang selesai pindah ke Riwayat)
              final activeRooms = rooms.where((r) => r.status.toLowerCase() != 'selesai').toList();

              // 2. Filter Tanggal & Waktu
              var filtered = activeRooms.where((r) {
                final rDate = DateTime.fromMillisecondsSinceEpoch(r.scheduledStart);

                switch (_selectedFilter) {
                  case 'Hari ini':
                    return rDate.isAfter(todayStart) && rDate.isBefore(todayEnd);
                  case '3 hari ke depan':
                    final limit = todayStart.add(const Duration(days: 3));
                    return rDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && rDate.isBefore(limit);
                  case '7 hari ke depan':
                    final limit = todayStart.add(const Duration(days: 7));
                    return rDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && rDate.isBefore(limit);
                  case 'Minggu ini':
                    final currentWeekday = now.weekday; // 1 = Mon
                    final mon = todayStart.subtract(Duration(days: currentWeekday - 1));
                    final sun = mon.add(const Duration(days: 7));
                    return rDate.isAfter(mon) && rDate.isBefore(sun);
                  case 'Bulan ini':
                    return rDate.year == now.year && rDate.month == now.month;
                  case 'Pilih tanggal':
                    if (_customFilterDate == null) return true;
                    return rDate.year == _customFilterDate!.year &&
                        rDate.month == _customFilterDate!.month &&
                        rDate.day == _customFilterDate!.day;
                  case 'Semua':
                  default:
                    return true;
                }
              }).toList();

              // 2. Filter Search Query
              if (_searchQuery.isNotEmpty) {
                filtered = filtered.where((r) {
                  final t = r.name.toLowerCase();
                  final c = r.code.toLowerCase();
                  return t.contains(_searchQuery) || c.contains(_searchQuery);
                }).toList();
              }

              // 3. Sorting
              filtered.sort((a, b) {
                if (_sortAscending) {
                  return a.scheduledStart.compareTo(b.scheduledStart);
                } else {
                  return b.scheduledStart.compareTo(a.scheduledStart);
                }
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada ruangan yang dibuat',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat ruang baru atau gabung menggunakan kode untuk memulai.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final room = filtered[idx];
                  final isHost = room.isHost;
                  final rDate = DateTime.fromMillisecondsSinceEpoch(room.scheduledStart);
                  final timeStr = '${rDate.day} ${_getMonthName(rDate.month)} • ${rDate.hour.toString().padLeft(2, '0')}:${rDate.minute.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      onTap: () => _navigateToRoom(room),
                      child: Row(
                        children: [
                          // ICON: Host vs Member
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isHost ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isHost ? Icons.bookmark_rounded : Icons.groups_rounded,
                              color: isHost ? const Color(0xFFD97706) : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Detail Ruang
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  room.code,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${room.durationMin} menit',
                                      style: AppTheme.bodySmall.copyWith(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: AppColors.textMuted,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Three dots menu button
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () => _showRoomActionMenu(context, room),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Belum ada ruangan yang dibuat',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToRoom(UserRoomIndex room) {
    if (room.status == 'selesai') {
      context.push('/session-summary/${room.roomId}?readOnly=true');
    } else if (room.status == 'berjalan') {
      context.push('/active-session/${room.roomId}');
    } else {
      context.push('/lobby/${room.roomId}');
    }
  }

  // ===================== THREE-DOTS MENU (HOST vs MEMBER) =====================
  void _showRoomActionMenu(BuildContext context, UserRoomIndex room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Sheet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: AppTheme.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                if (room.isHost) ...[
                  // HOST: Edit Ruang & Hapus Ruang
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: const Text('Edit Ruang', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Ubah judul, jadwal, durasi, dan catatan'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditRoomSheet(context, room);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                    title: const Text('Hapus Ruang', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Hapus ruangan ini secara permanen'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteRoom(context, room.roomId);
                    },
                  ),
                ] else ...[
                  // MEMBER: Lihat Detail & Keluar dari Ruang
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Informasi ruang dan anggota terhubung'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRoomDetailSheet(context, room);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                    title: const Text('Keluar dari Ruang', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Berhenti mengikuti sesi ruangan ini'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmLeaveRoom(context, room.roomId);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== EDIT RUANG (HOST) =====================
  void _showEditRoomSheet(BuildContext context, UserRoomIndex room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditRoomSheetContent(room: room),
    );
  }

  // ===================== LIHAT DETAIL (MEMBER) =====================
  void _showRoomDetailSheet(BuildContext context, UserRoomIndex room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RoomDetailSheetContent(room: room),
    );
  }

  // ===================== CONFIRM DIALOGS =====================
  void _confirmDeleteRoom(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Ruangan?'),
        content: const Text(
          'Ruangan ini akan dihapus secara permanen untuk seluruh anggota. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(roomRepositoryProvider).deleteRoom(roomId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ruangan berhasil dihapus'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveRoom(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Ruang?'),
        content: const Text(
          'Anda akan keluar dari ruangan ini dan tidak lagi terdaftar sebagai anggota sesi.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(roomRepositoryProvider).leaveRoom(roomId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil keluar dari ruangan'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Sheet konten untuk Edit Ruang (Host)
class _EditRoomSheetContent extends ConsumerStatefulWidget {
  final UserRoomIndex room;
  const _EditRoomSheetContent({required this.room});

  @override
  ConsumerState<_EditRoomSheetContent> createState() => _EditRoomSheetContentState();
}

class _EditRoomSheetContentState extends ConsumerState<_EditRoomSheetContent> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _selectedDateTime;
  late int _durationMin;
  late String _reminder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.room.name);
    _noteCtrl = TextEditingController(text: widget.room.note ?? '');
    _selectedDateTime = DateTime.fromMillisecondsSinceEpoch(widget.room.scheduledStart);
    _durationMin = widget.room.durationMin;
    _reminder = widget.room.reminder ?? '10 menit sebelumnya';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul ruang tidak boleh kosong'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(roomRepositoryProvider).updateRoom(
            roomId: widget.room.roomId,
            name: title,
            durationMinutes: _durationMin,
            note: _noteCtrl.text.trim(),
            reminder: _reminder,
            scheduledStart: _selectedDateTime.millisecondsSinceEpoch,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan ruang berhasil disimpan'), backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMembersProvider(widget.room.roomId));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Ruang',
                  style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Judul Ruang
            Text('Judul Ruang', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Waktu Mulai
            Text('Waktu Mulai', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}  •  ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                      style: AppTheme.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Durasi Sesi
            Text('Durasi Sesi', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final standardDurations = [25, 45, 60, 90];
                final durationItems = <DropdownMenuItem<int>>[
                  const DropdownMenuItem(value: 25, child: Text('25 menit (Pomodoro)')),
                  const DropdownMenuItem(value: 45, child: Text('45 menit (Standar)')),
                  const DropdownMenuItem(value: 60, child: Text('60 menit (Intensif)')),
                  const DropdownMenuItem(value: 90, child: Text('90 menit (Panjang)')),
                  if (!standardDurations.contains(_durationMin))
                    DropdownMenuItem(value: _durationMin, child: Text('$_durationMin menit (Kustom)')),
                ];

                return DropdownButtonFormField<int>(
                  initialValue: _durationMin,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: durationItems,
                  onChanged: (val) {
                    if (val != null) setState(() => _durationMin = val);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // Pengingat
            Text('Pengingat', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final standardReminders = [
                  '5 menit sebelumnya',
                  '10 menit sebelumnya',
                  '15 menit sebelumnya',
                  'Tidak ada',
                ];
                final reminderItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: '5 menit sebelumnya', child: Text('5 menit sebelumnya')),
                  const DropdownMenuItem(value: '10 menit sebelumnya', child: Text('10 menit sebelumnya')),
                  const DropdownMenuItem(value: '15 menit sebelumnya', child: Text('15 menit sebelumnya')),
                  const DropdownMenuItem(value: 'Tidak ada', child: Text('Tidak ada')),
                  if (!standardReminders.contains(_reminder))
                    DropdownMenuItem(value: _reminder, child: Text(_reminder)),
                ];
                final effectiveReminder = reminderItems.any((it) => it.value == _reminder)
                    ? _reminder
                    : 'Tidak ada';

                return DropdownButtonFormField<String>(
                  initialValue: effectiveReminder,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: reminderItems,
                  onChanged: (val) {
                    if (val != null) setState(() => _reminder = val);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // Catatan
            Text('Catatan Ruang', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan jika diperlukan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 18),

            // ANGGOTA TERHUBUNG (Live Member List replacing link/code per point 6)
            Text(
              'Anggota Terhubung',
              style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Belum ada anggota yang bergabung.',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: members.map((m) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            AvatarCircle(name: m.name, photoUrl: m.photoUrl, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                m.name,
                                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (m.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Host',
                                  style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan Perubahan & Hapus Ruang
            PrimaryButton(
              text: 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _saveChanges,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(roomRepositoryProvider).deleteRoom(widget.room.roomId);
              },
              child: const Text('Hapus Ruang', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet konten untuk Lihat Detail (Member)
class _RoomDetailSheetContent extends ConsumerWidget {
  final UserRoomIndex room;
  const _RoomDetailSheetContent({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(room.roomId));
    final date = DateTime.fromMillisecondsSinceEpoch(room.scheduledStart);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Kode Ruang & Waktu
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kode Ruangan', style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted)),
                      Text(room.code, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Waktu Pelaksanaan', style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted)),
                      Text(
                        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Durasi Sesi', style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted)),
                      Text('${room.durationMin} menit', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
                    ],
                  ),
                  if (room.note?.isNotEmpty == true) ...[
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Catatan', style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            room.note!,
                            textAlign: TextAlign.end,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Anggota Terhubung
            Text(
              'Anggota Terhubung',
              style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            membersAsync.when(
              data: (members) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: members.map((m) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            AvatarCircle(name: m.name, photoUrl: m.photoUrl, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                m.name,
                                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (m.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Host',
                                  style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Keluar dari Ruang Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(roomRepositoryProvider).leaveRoom(room.roomId);
              },
              child: const Text('Keluar dari Ruang', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
