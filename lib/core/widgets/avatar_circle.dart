import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarCircle extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AvatarCircle({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 44,
    this.backgroundColor,
    this.onTap,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'K';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Color _generateBgColor(String text) {
    if (backgroundColor != null) return backgroundColor!;
    final hash = text.hashCode.abs();
    final colors = [
      const Color(0xFF2463FF),
      const Color(0xFF101653),
      const Color(0xFF0284C7),
      const Color(0xFF4F46E5),
      const Color(0xFF059669),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    Widget buildImage() {
      final url = photoUrl!.trim();
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
        );
      }
      if (url.startsWith('data:image/') || url.startsWith('base64,')) {
        try {
          return Image.memory(
            base64Decode(url.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          );
        } catch (_) {
          return _buildInitials();
        }
      }
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
        );
      }
      // Path lokal file dari image_picker
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          );
        }
      } catch (_) {}

      return _buildInitials();
    }

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _generateBgColor(name),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101653),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto ? buildImage() : _buildInitials(),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: AppTheme.labelMedium.copyWith(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
