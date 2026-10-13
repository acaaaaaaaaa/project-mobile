import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class S00LandingScreen extends StatefulWidget {
  const S00LandingScreen({super.key});

  @override
  State<S00LandingScreen> createState() => _S00LandingScreenState();
}

class _S00LandingScreenState extends State<S00LandingScreen> {
  // 0: Masuk (Sign in), 1: Daftar (Sign up)
  // Default index 1 (Daftar / Sign up) sesuai referensi desain
  int _selectedIndex = 1;

  void _onSelect(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onTapButton(int index) {
    _onSelect(index);
    // Beri sedikit jeda halus agar transisi pill putih terlihat sebelum pindah halaman
    Future.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      if (index == 0) {
        context.go('/login');
      } else {
        context.go('/register');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071930),
      body: Stack(
        children: [
          // 1. Gambar Latar Belakang 'backround-landing.png'
          Positioned.fill(
            child: Image.asset(
              'assets/images/backround-landing.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/background-landing.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                );
              },
            ),
          ),

          // 2. Subtle Dark Gradient Overlay di bagian bawah agar teks & tombol sangat kontras dan mudah dibaca
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 0.72, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF041021).withValues(alpha: 0.60),
                    const Color(0xFF041021).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Teks & Header (Tanpa Topi & Kerkom Badge)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  // Headline "Selamat Datang!"
                  Text(
                    'Selamat Datang!',
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Selesaikan tugas dan kerja kelompok bersama tanpa distraksi digital.',
                    style: AppTheme.bodyLarge.copyWith(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 90), // Space for bottom button
                ],
              ),
            ),
          ),

          // 4. Interactive Dock Toggle: "Masuk" & "Daftar" di ujung tampilan UI paling bawah
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF09182F).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pillWidth = constraints.maxWidth / 2;
                    return Stack(
                      children: [
                        // Kapsul putih beranimasi geser (Sliding Pill Indicator)
                        AnimatedAlign(
                          alignment: _selectedIndex == 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            width: pillWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Row tombol interaktif dengan hover & tap
                        Row(
                          children: [
                            // Tombol Masuk (Sign in / Login)
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => _onSelect(0),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) => _onSelect(0),
                                  onTap: () => _onTapButton(0),
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: AppTheme.labelLarge.copyWith(
                                        color: _selectedIndex == 0
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: _selectedIndex == 0
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      child: const Text('Masuk'),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Tombol Daftar (Sign up / Register)
                            Expanded(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => _onSelect(1),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) => _onSelect(1),
                                  onTap: () => _onTapButton(1),
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: AppTheme.labelLarge.copyWith(
                                        color: _selectedIndex == 1
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: _selectedIndex == 1
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      child: const Text('Daftar'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
