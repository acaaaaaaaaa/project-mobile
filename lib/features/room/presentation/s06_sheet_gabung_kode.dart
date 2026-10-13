import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../presentation/room_controller.dart';

class S06SheetGabungKode extends ConsumerStatefulWidget {
  const S06SheetGabungKode({super.key});

  @override
  ConsumerState<S06SheetGabungKode> createState() => _S06SheetGabungKodeState();
}

class _S06SheetGabungKodeState extends ConsumerState<S06SheetGabungKode> {
  final _codeController = TextEditingController();
  final _linkController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _linkController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleJoin(String rawCode) async {
    final code = rawCode.replaceAll('-', '').trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Masukkan kode ruang 6 karakter');
      return;
    }

    if (code.length < 4) {
      setState(() => _errorMessage = 'Format kode tidak valid (minimal 4-6 karakter)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(roomRepositoryProvider);
      final room = await repo.joinRoomByCode(code);
      if (mounted) {
        Navigator.pop(context);
        context.push('/lobby/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinLinkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gabung lewat Link',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempel link undangan KerKom (contoh: https://kerkom.app/j/K7M2Q9)',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              autofocus: true,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.navy),
              decoration: InputDecoration(
                hintText: 'https://kerkom.app/j/...',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: const Color(0xFFF4F8FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final input = _linkController.text.trim();
              if (input.isNotEmpty) {
                // Ekstrak kode dari URL jika berbentuk path https://kerkom.app/j/CODE
                final uri = Uri.tryParse(input);
                if (uri != null && uri.pathSegments.isNotEmpty) {
                  final code = uri.pathSegments.last;
                  _handleJoin(code);
                } else {
                  _handleJoin(input);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Gabung', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _codeController.text.toUpperCase();

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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gabung ke Ruang',
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
          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Masukkan kode ruang',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // 6 Individual Boxes (Mockup 1)
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hidden TextField to receive keyboard input
                Opacity(
                  opacity: 0.0,
                  child: SizedBox(
                    height: 52,
                    child: TextField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      onSubmitted: (val) => _handleJoin(val),
                    ),
                  ),
                ),

                // 6 Visual Character Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final char = index < text.length ? text[index] : '';
                    final isFocused = index == text.length && _focusNode.hasFocus;

                    return Container(
                      width: 46,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused ? AppColors.primary : AppColors.cardBorder,
                          width: isFocused ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF101653).withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: AppTheme.headlineMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
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

          const SizedBox(height: 24),

          // Tombol "Gabung ke Ruang"
          PrimaryButton(
            text: 'Gabung ke Ruang',
            isLoading: _isLoading,
            onPressed: () => _handleJoin(_codeController.text),
          ),
          const SizedBox(height: 18),

          // Divider "atau"
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'atau',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Tombol "Gabung lewat Link"
          SecondaryButton(
            text: 'Gabung lewat Link',
            icon: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
            onPressed: _showJoinLinkDialog,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
