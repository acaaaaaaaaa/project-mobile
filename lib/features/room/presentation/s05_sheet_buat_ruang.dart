import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../domain/room_models.dart';
import '../presentation/room_controller.dart';

class S05SheetBuatRuang extends ConsumerStatefulWidget {
  const S05SheetBuatRuang({super.key});

  @override
  ConsumerState<S05SheetBuatRuang> createState() => _S05SheetBuatRuangState();
}

class _S05SheetBuatRuangState extends ConsumerState<S05SheetBuatRuang> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 0);
  String _selectedReminder = '15 menit sebelum';

  bool _isLoading = false;
  String? _errorMessage;
  RoomModel? _createdRoom;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _calculateDurationMinutes() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    var endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Melewati tengah malam
    }
    final diff = endMinutes - startMinutes;
    return diff > 0 ? diff : 45;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTimeRange() async {
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Pilih Waktu Mulai',
    );
    if (pickedStart == null) return;

    if (!mounted) return;
    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Pilih Waktu Selesai',
    );
    if (pickedEnd == null) return;

    setState(() {
      _startTime = pickedStart;
      _endTime = pickedEnd;
    });
  }

  Future<void> _handleCreateRoom() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Judul kegiatan wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(roomRepositoryProvider);
      final duration = _calculateDurationMinutes();
      final room = await repo.createRoom(
        name: title,
        durationMinutes: duration,
        reminder: _selectedReminder,
        note: _noteController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _createdRoom = room;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAll() {
    if (_createdRoom == null) return;
    final code = _createdRoom!.code;
    final link = 'https://kerkom.app/j/$code';
    final allText = 'KerKom: ${_titleController.text}\n'
        'Jadwal: ${_formatDate(_selectedDate)} (${_formatTime(_startTime)} - ${_formatTime(_endTime)})\n'
        'Pengingat: $_selectedReminder\n'
        'Catatan: ${_noteController.text}\n'
        'Kode Ruang: $code\n'
        'Link Meeting: $link';

    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua detail ruang berhasil disalin!'),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToMembers() {
    if (_createdRoom == null) return;
    final code = _createdRoom!.code;
    final link = 'https://kerkom.app/j/$code';
    final text = 'Yuk gabung ruang kerja kelompok "${_titleController.text}" di KerKom!\n'
        'Tanggal: ${_formatDate(_selectedDate)}\n'
        'Waktu: ${_formatTime(_startTime)} - ${_formatTime(_endTime)}\n'
        'Catatan: ${_noteController.text}\n'
        'Kode Ruang: $code\n'
        'Link: $link';

    try {
      SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      _copyToClipboard(text, 'Undangan');
    }

    Navigator.pop(context);
    context.push('/lobby/${_createdRoom!.id}');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _createdRoom == null ? 'Buat Ruang Kerja' : 'Ruang Berhasil Dibuat',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  fontSize: 20,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content Switcher
          if (_createdRoom == null) _buildCreateForm() else _buildSuccessState(),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    final timeStr = '${_formatTime(_startTime)} - ${_formatTime(_endTime)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label Judul Kegiatan
        Text(
          'Judul kegiatan',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),

        // Input Judul Kegiatan
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: TextField(
            controller: _titleController,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.navy,
                size: 20,
              ),
              hintText: 'Misal: Tugas Akhir HCI Kelompok 4',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Row Tanggal & Waktu
        Row(
          children: [
            // Kolom Tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.navy, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDate),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Kolom Waktu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickTimeRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.navy, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeStr,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Input Pengingat (Menit / Jam / Hari / Minggu)
        Text(
          'Pengingat',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReminder,
              isExpanded: true,
              icon: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
              style: AppTheme.bodyMedium.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
              items: const [
                DropdownMenuItem(value: '15 menit sebelum', child: Text('15 menit sebelum')),
                DropdownMenuItem(value: '30 menit sebelum', child: Text('30 menit sebelum')),
                DropdownMenuItem(value: '1 jam sebelum', child: Text('1 jam sebelum')),
                DropdownMenuItem(value: '1 hari sebelum', child: Text('1 hari sebelum')),
                DropdownMenuItem(value: '1 minggu sebelum', child: Text('1 minggu sebelum')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedReminder = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Input Catatan Ruang
        Text(
          'Catatan / Agenda',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 2,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.notes_rounded, color: AppColors.navy, size: 20),
              ),
              hintText: 'Misal: Diskusi tugas bab 3, pembagian tugas kelompok...',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Info Card "Ruang akan dibuat dengan"
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ruang akan dibuat dengan',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckItem('Kode ruang'),
                    const SizedBox(height: 6),
                    _buildCheckItem('Link meeting (KerKom)'),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),
        PrimaryButton(
          text: 'Buat Ruang',
          isLoading: _isLoading,
          onPressed: _handleCreateRoom,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final room = _createdRoom!;
    final code = room.code.replaceAll('-', '');
    final codeChars = code.split('');
    final link = 'https://kerkom.app/j/${room.code}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Checkmark Icon
        Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Ruang Berhasil Dibuat',
            style: AppTheme.headlineSmall.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Detail Kegiatan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.navy, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Judul kegiatan',
                          style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          _titleController.text,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.divider),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.navy, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal', style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted)),
                            Text(
                              _formatDate(_selectedDate),
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.navy, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Waktu', style: AppTheme.labelSmall.copyWith(color: AppColors.textMuted)),
                            Text(
                              '${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_noteController.text.trim().isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),
                Text(
                  'Catatan: ${_noteController.text.trim()}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Kode Ruang
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kode Ruang',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: codeChars.map((char) {
                        return Container(
                          width: 38,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder, width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A101653),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: AppTheme.headlineSmall.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _copyToClipboard(room.code, 'Kode ruang'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Link Meeting (KerKom)',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              link,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _copyToClipboard(link, 'Link meeting'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        PrimaryButton(
          text: 'Masuk ke Lobi Ruang',
          icon: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_createdRoom != null) {
              Navigator.pop(context);
              context.push('/lobby/${_createdRoom!.id}');
            }
          },
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          text: 'Bagikan ke Anggota',
          icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
          onPressed: _shareToMembers,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          text: 'Salin Semua',
          icon: const Icon(Icons.copy_all_rounded, color: AppColors.primary, size: 20),
          onPressed: _copyAll,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
