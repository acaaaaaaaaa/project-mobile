import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101653).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Dashboard',
                  ),
                  _buildNavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_alt_rounded,
                    label: 'Ruang',
                  ),
                  _buildNavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.access_time_rounded,
                    selectedIcon: Icons.history_rounded,
                    label: 'Riwayat',
                  ),
                  _buildNavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 44 : 36,
                height: isSelected ? 44 : 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    size: isSelected ? 24 : 22,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: isSelected ? AppColors.navy : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
