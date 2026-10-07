import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Widget? badge;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.badge,
    this.backgroundColor,
  });

  Color _getDeterministicColor(String text) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF0D9488), // Teal
      const Color(0xFF0284C7), // Sky
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFD97706), // Amber
      const Color(0xFFE11D48), // Rose
    ];
    int hash = text.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  String _getInitials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? _getDeterministicColor(name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: badge!,
          ),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
