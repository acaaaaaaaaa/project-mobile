import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarCircle extends StatefulWidget {
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

  @override
  State<AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends State<AvatarCircle> {
  ImageProvider? _photo;

  String get name => widget.name;
  String? get photoUrl => widget.photoUrl;
  double get size => widget.size;
  Color? get backgroundColor => widget.backgroundColor;
  VoidCallback? get onTap => widget.onTap;

  @override
  void initState() {
    super.initState();
    _resolvePhoto();
  }

  @override
  void didUpdateWidget(covariant AvatarCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != photoUrl) _resolvePhoto();
  }

  void _resolvePhoto() {
    final url = photoUrl?.trim() ?? '';
    _photo = null;
    if (url.isEmpty) return;
    try {
      if (url.startsWith('assets/')) {
        _photo = AssetImage(url);
      } else if (url.startsWith('data:image/') || url.startsWith('base64,')) {
        // Keep the decoded bytes/provider stable across telemetry/heartbeat builds.
        _photo = MemoryImage(base64Decode(url.split(',').last));
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        _photo = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) _photo = FileImage(file);
      }
    } catch (_) {
      _photo = null;
    }
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'K';
    final parts = trimmed.split(RegExp(r'\s+'));
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
      child: _photo == null
          ? _buildInitials()
          : Image(
              image: _photo!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => _buildInitials(),
            ),
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
