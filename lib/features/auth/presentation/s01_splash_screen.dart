import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kerkom_morphing_logo.dart';

class S01SplashScreen extends StatefulWidget {
  final bool autoNavigate;

  const S01SplashScreen({super.key, this.autoNavigate = true});

  @override
  State<S01SplashScreen> createState() => _S01SplashScreenState();
}

class _S01SplashScreenState extends State<S01SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    if (widget.autoNavigate) {
      _startSessionCheck();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startSessionCheck() async {
    // Animasi progress bar halus selama ~2.2 detik untuk menampilkan logo bergerak
    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (mounted) {
        setState(() {
          _progress = i / 20.0;
        });
      }
    }

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.go('/home');
    } else {
      context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Radial Soft Blue Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.1),
                  radius: 0.85,
                  colors: [
                    Color(0xFFE8F7FC),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 10),
                    // Logo Metamorfosis Animasi K (Sesuai Screen Recording)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const KerkomMorphingLogo(size: 260),
                            const SizedBox(height: 24),
                            Text(
                              'kerkom',
                              style: AppTheme.headlineLarge.copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                                color: const Color(0xFF03045E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kerja kelompok tanpa distraksi',
                              style: AppTheme.bodyLarge.copyWith(
                                color: const Color(0xFF0077B6),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Progress Bar Indikator Halus di Bawah
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 150,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 150 * _progress,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00B4D8),
                                    Color(0xFF0077B6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(const Color(0xFF00B4D8), _progress >= 0.33),
                            const SizedBox(width: 8),
                            _dot(const Color(0xFF0077B6), _progress >= 0.66),
                            const SizedBox(width: 8),
                            _dot(const Color(0xFF03045E), _progress >= 0.99),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color activeColor, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isActive ? activeColor : const Color(0xFFCBD5E1),
      ),
    );
  }
}
