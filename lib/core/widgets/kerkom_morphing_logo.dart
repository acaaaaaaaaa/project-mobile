import 'dart:math' as math;
import 'package:flutter/material.dart';

class KerkomMorphingLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const KerkomMorphingLogo({
    super.key,
    this.size = 280,
    this.animate = true,
  });

  @override
  State<KerkomMorphingLogo> createState() => _KerkomMorphingLogoState();
}

class _KerkomMorphingLogoState extends State<KerkomMorphingLogo>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _orbitController;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    if (widget.animate) {
      _morphController.repeat();
      _orbitController.repeat();
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _orbitController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_morphController, _orbitController, _idleController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _KerkomLogoPainter(
            morphProgress: _morphController.value,
            orbitProgress: _orbitController.value,
            idleProgress: _idleController.value,
          ),
        );
      },
    );
  }
}

class _KerkomLogoPainter extends CustomPainter {
  final double morphProgress;
  final double orbitProgress;
  final double idleProgress;

  _KerkomLogoPainter({
    required this.morphProgress,
    required this.orbitProgress,
    required this.idleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Lintasan Orbit Berputar (Orbit Pulse Flow)
    _drawOrbit(canvas);

    // 2. Idle Canvas Breathing (logoAssembleComplete)
    final idleScale = 1.0 + (idleProgress * 0.025);
    canvas.save();
    canvas.translate(256, 256);
    canvas.scale(idleScale, idleScale);
    canvas.translate(-256, -256);

    // Shadow glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(const Offset(256, 256), 110, glowPaint);

    // 3. Batang Pena Fountain -> Pilar Vertikal Utama 'K'
    _drawPillar(canvas);

    // 4. Mata Pena (Pen Nib)
    _drawPenNib(canvas);

    // 5. Lengan Atas 'K' (Buku Terbuka / Laptop)
    _drawUpperArm(canvas);

    // 6. Lengan Bawah 'K' (Jangka / Penggaris)
    _drawLowerArm(canvas);

    // 7. Meja Diskusi Bersama (Ink Table Arc)
    _drawTableArc(canvas);

    // 8. Anggota Kelompok Mahasiswa (2 Student Avatars)
    _drawStudents(canvas);

    // 9. Bintang Sinergi / Spark Star
    _drawSparkStar(canvas);

    canvas.restore();
    canvas.restore();
  }

  void _drawOrbit(Canvas canvas) {
    canvas.save();
    canvas.translate(256, 256);
    canvas.rotate(orbitProgress * 2 * math.pi);

    final orbitPaint = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw dashed circle
    const r = 192.0;
    const dashCount = 36;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * math.pi / dashCount);
      const sweepAngle = (math.pi / dashCount) * 0.9;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        startAngle,
        sweepAngle,
        false,
        orbitPaint,
      );
    }

    // Satellite orbiting dots
    final dot1 = Paint()..color = const Color(0xFF00B4D8);
    final dot2 = Paint()..color = const Color(0xFF90E0EF);
    final dot3 = Paint()..color = const Color(0xFF0077B6);
    final dot4 = Paint()..color = const Color(0xFFCAF0F8);

    canvas.drawCircle(const Offset(r, 0), 5.0, dot1);
    canvas.drawCircle(const Offset(-r, 0), 4.5, dot2);
    canvas.drawCircle(const Offset(0, -r), 5.5, dot3);
    canvas.drawCircle(const Offset(0, r), 4.0, dot4);

    canvas.restore();
  }

  void _drawPillar(Canvas canvas) {
    canvas.save();

    // Keyframes: penBodyToPillar
    double tx = 0.0;
    double ty = 0.0;
    double sy = 1.0;
    double sx = 1.0;
    double opacity = 1.0;

    if (morphProgress < 0.25) {
      final t = morphProgress / 0.25;
      tx = 74.0 * (1 - t * 0.1);
      ty = 20.0 * (1 - t);
      sx = 0.7 + (0.15 * t);
      sy = 0.7 + (0.32 * t);
      opacity = 0.2 + 0.8 * t;
    } else if (morphProgress < 0.45) {
      final t = (morphProgress - 0.25) / 0.20;
      tx = 74.0 * (1.0 - t);
      ty = 0.0;
      sx = 0.85 + (0.15 * t);
      sy = 1.02 - (0.02 * t);
      opacity = 1.0;
    }

    canvas.translate(tx, ty);
    canvas.translate(166, 256);
    canvas.scale(sx, sy);
    canvas.translate(-166, -256);

    // Linear gradient #0077B6 -> #03045E
    final pillarRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(140, 128, 52, 256),
      const Radius.circular(26),
    );
    final pillarPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0077B6), Color(0xFF03045E)],
      ).createShader(pillarRect.outerRect)
      ..color = Colors.white.withValues(alpha: opacity);

    canvas.drawRRect(pillarRect, pillarPaint);

    // Bookmark / Ribbon
    final ribbonPath = Path()
      ..moveTo(152, 136)
      ..lineTo(180, 136)
      ..lineTo(180, 204)
      ..lineTo(166, 193)
      ..lineTo(152, 204)
      ..close();
    final ribbonPaint = Paint()
      ..color = const Color(0xFF90E0EF).withValues(alpha: 0.95 * opacity);
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Decorative Lines on spine
    final linePaint = Paint()
      ..color = const Color(0xFFCAF0F8).withValues(alpha: 0.40 * opacity)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(150, 230), const Offset(182, 230), linePaint);
    canvas.drawLine(const Offset(150, 242), const Offset(182, 242), linePaint);

    canvas.restore();
  }

  void _drawPenNib(Canvas canvas) {
    // Keyframe penNibMorph
    double ty = 0.0;
    double scale = 1.0;
    double opacity = 1.0;

    if (morphProgress < 0.22) {
      final t = morphProgress / 0.22;
      ty = 18.0 * (1 - t);
      scale = 1.0 + (0.1 * t);
      opacity = 1.0;
    } else if (morphProgress < 0.38) {
      final t = (morphProgress - 0.22) / 0.16;
      ty = -24.0 * t;
      scale = 1.1 - (0.5 * t);
      opacity = 1.0 - t;
    } else {
      opacity = 0.0;
    }

    if (opacity <= 0.0) return;

    canvas.save();
    canvas.translate(214, 105);
    canvas.translate(0, ty);
    canvas.scale(scale, scale);
    canvas.translate(-214, -105);

    final nibPath = Path()
      ..moveTo(204, 128)
      ..lineTo(214, 96)
      ..lineTo(224, 128)
      ..close();
    final nibPaint = Paint()..color = const Color(0xFF00B4D8).withValues(alpha: opacity);
    canvas.drawPath(nibPath, nibPaint);

    // Tip line & center dot
    final tipLinePaint = Paint()
      ..color = const Color(0xFFCAF0F8).withValues(alpha: opacity)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(214, 116), const Offset(214, 97), tipLinePaint);
    canvas.drawCircle(
      const Offset(214, 116),
      2.5,
      Paint()..color = const Color(0xFFCAF0F8).withValues(alpha: opacity),
    );

    canvas.restore();
  }

  void _drawUpperArm(Canvas canvas) {
    canvas.save();

    // Keyframe stationeryTopMorph
    double tx = 0.0;
    double ty = 0.0;
    double rot = 0.0;
    double s = 1.0;
    double opacity = 1.0;

    if (morphProgress < 0.20) {
      final t = morphProgress / 0.20;
      tx = 120.0 - 60.0 * t;
      ty = -80.0 + 50.0 * t;
      rot = -35.0 + 17.0 * t;
      s = 0.3 + 0.6 * t;
      opacity = 0.9 * t;
    } else if (morphProgress < 0.40) {
      final t = (morphProgress - 0.20) / 0.20;
      tx = 60.0 - 35.0 * t;
      ty = -30.0 + 20.0 * t;
      rot = -18.0 + 12.0 * t;
      s = 0.9 + 0.15 * t;
      opacity = 1.0;
    } else if (morphProgress < 0.55) {
      final t = (morphProgress - 0.40) / 0.15;
      tx = 25.0 * (1 - t);
      ty = -10.0 * (1 - t);
      rot = -6.0 * (1 - t);
      s = 1.05 - 0.05 * t;
      opacity = 1.0;
    }

    canvas.translate(236, 160);
    canvas.translate(tx, ty);
    canvas.rotate(rot * math.pi / 180.0);
    canvas.scale(s, s);
    canvas.translate(-236, -160);

    // Gradient Upper #90E0EF -> #00B4D8 -> #0077B6
    final armRect = const Rect.fromLTWH(200, 140, 140, 130);
    final armPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF90E0EF), Color(0xFF00B4D8), Color(0xFF0077B6)],
      ).createShader(armRect)
      ..color = Colors.white.withValues(alpha: opacity);

    // Book spine contour
    final bookContour = Path()
      ..moveTo(206, 230)
      ..cubicTo(235, 175, 275, 155, 330, 180)
      ..cubicTo(348, 190, 340, 212, 316, 216)
      ..cubicTo(265, 224, 235, 242, 206, 262)
      ..close();
    canvas.drawPath(bookContour, armPaint);

    // Rotated rounded pill
    canvas.save();
    canvas.translate(228, 158);
    canvas.rotate(42 * math.pi / 180.0);
    final upperPill = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 48, 130),
      const Radius.circular(24),
    );
    canvas.drawRRect(upperPill, armPaint);
    canvas.restore();

    // Notebook lines
    final linePaint = Paint()
      ..color = const Color(0xFFCAF0F8).withValues(alpha: 0.80 * opacity)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(262, 184), const Offset(296, 154), linePaint);
    canvas.drawLine(const Offset(272, 196), const Offset(306, 166), linePaint);

    canvas.restore();
  }

  void _drawLowerArm(Canvas canvas) {
    canvas.save();

    // Keyframe stationeryBottomMorph
    double tx = 0.0;
    double ty = 0.0;
    double rot = 0.0;
    double s = 1.0;
    double opacity = 1.0;

    if (morphProgress < 0.24) {
      final t = morphProgress / 0.24;
      tx = 110.0 - 60.0 * t;
      ty = 110.0 - 65.0 * t;
      rot = 40.0 - 20.0 * t;
      s = 0.3 + 0.6 * t;
      opacity = 0.9 * t;
    } else if (morphProgress < 0.42) {
      final t = (morphProgress - 0.24) / 0.18;
      tx = 50.0 - 35.0 * t;
      ty = 45.0 - 30.0 * t;
      rot = 20.0 - 12.0 * t;
      s = 0.9 + 0.16 * t;
      opacity = 1.0;
    } else if (morphProgress < 0.60) {
      final t = (morphProgress - 0.42) / 0.18;
      tx = 15.0 * (1 - t);
      ty = 15.0 * (1 - t);
      rot = 8.0 * (1 - t);
      s = 1.06 - 0.06 * t;
      opacity = 1.0;
    }

    canvas.translate(220, 270);
    canvas.translate(tx, ty);
    canvas.rotate(rot * math.pi / 180.0);
    canvas.scale(s, s);
    canvas.translate(-220, -270);

    // Gradient lower #00B4D8 -> #03045E
    final lowerRect = const Rect.fromLTWH(216, 270, 130, 135);
    final armPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00B4D8), Color(0xFF03045E)],
      ).createShader(lowerRect)
      ..color = Colors.white.withValues(alpha: opacity);

    canvas.save();
    canvas.translate(216, 270);
    canvas.rotate(-42 * math.pi / 180.0);
    final lowerPill = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 48, 135),
      const Radius.circular(24),
    );
    canvas.drawRRect(lowerPill, armPaint);
    canvas.restore();

    // Circular compass hinge
    canvas.drawCircle(
      const Offset(216, 270),
      14,
      Paint()..color = const Color(0xFF0077B6).withValues(alpha: 0.85 * opacity),
    );
    canvas.drawCircle(
      const Offset(216, 270),
      6,
      Paint()..color = const Color(0xFFCAF0F8).withValues(alpha: opacity),
    );

    canvas.restore();
  }

  void _drawTableArc(Canvas canvas) {
    // Anim-ink-table (stroke-dash draw)
    double progress = 1.0;
    if (morphProgress < 0.40) {
      progress = morphProgress / 0.40;
    }

    final path = Path()
      ..moveTo(194, 322)
      ..quadraticBezierTo(258, 350, 326, 312);

    final tablePaint = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: progress.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, tablePaint);
  }

  void _drawStudents(Canvas canvas) {
    // Mahasiswa 1 (Atas) - anim-stud-top
    double tx1 = 344.0;
    double ty1 = 142.0;
    double s1 = 1.0;
    double op1 = 1.0;

    if (morphProgress < 0.35) {
      final t = morphProgress / 0.35;
      tx1 = 400.0 - 30.0 * t;
      ty1 = 80.0 + 40.0 * t;
      s1 = 0.7 * t;
      op1 = 0.7 * t;
    } else if (morphProgress < 0.52) {
      final t = (morphProgress - 0.35) / 0.17;
      tx1 = 370.0 - 26.0 * t;
      ty1 = 120.0 + 22.0 * t;
      s1 = 0.7 + 0.52 * t;
      op1 = 1.0;
    } else if (morphProgress < 0.70) {
      final t = (morphProgress - 0.52) / 0.18;
      tx1 = 344.0;
      ty1 = 142.0;
      s1 = 1.22 - 0.22 * t;
      op1 = 1.0;
    }

    _drawStudentAvatar(canvas, Offset(tx1, ty1), s1, op1, const Color(0xFF00B4D8), const Color(0xFF03045E));

    // Mahasiswa 2 (Bawah) - anim-stud-bot
    double tx2 = 332.0;
    double ty2 = 368.0;
    double s2 = 1.0;
    double op2 = 1.0;

    if (morphProgress < 0.38) {
      final t = morphProgress / 0.38;
      tx2 = 390.0 - 30.0 * t;
      ty2 = 420.0 - 30.0 * t;
      s2 = 0.7 * t;
      op2 = 0.7 * t;
    } else if (morphProgress < 0.56) {
      final t = (morphProgress - 0.38) / 0.18;
      tx2 = 360.0 - 28.0 * t;
      ty2 = 390.0 - 22.0 * t;
      s2 = 0.7 + 0.52 * t;
      op2 = 1.0;
    } else if (morphProgress < 0.72) {
      final t = (morphProgress - 0.56) / 0.16;
      tx2 = 332.0;
      ty2 = 368.0;
      s2 = 1.22 - 0.22 * t;
      op2 = 1.0;
    }

    _drawStudentAvatar(canvas, Offset(tx2, ty2), s2, op2, const Color(0xFF0077B6), const Color(0xFF00B4D8));
  }

  void _drawStudentAvatar(
    Canvas canvas,
    Offset position,
    double scale,
    double opacity,
    Color circleColor,
    Color capColor,
  ) {
    if (opacity <= 0.0) return;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale, scale);

    // Outer circle
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()..color = circleColor.withValues(alpha: opacity),
    );
    // Inner circle
    canvas.drawCircle(
      Offset.zero,
      13,
      Paint()..color = const Color(0xFFCAF0F8).withValues(alpha: opacity),
    );

    // Graduation Cap Polygon
    final capPath = Path()
      ..moveTo(0, -16)
      ..lineTo(12, -10)
      ..lineTo(0, -4)
      ..lineTo(-12, -10)
      ..close();
    canvas.drawPath(
      capPath,
      Paint()..color = capColor.withValues(alpha: 0.95 * opacity),
    );

    canvas.restore();
  }

  void _drawSparkStar(Canvas canvas) {
    // Keyframe synergyGlowSpark
    double scale = 1.0;
    double rot = 180.0;
    double opacity = 1.0;

    if (morphProgress < 0.45) {
      scale = 0.0;
      opacity = 0.0;
    } else if (morphProgress < 0.62) {
      final t = (morphProgress - 0.45) / 0.17;
      scale = 1.4 * t;
      rot = 90.0 * t;
      opacity = t;
    } else if (morphProgress < 0.75) {
      final t = (morphProgress - 0.62) / 0.13;
      scale = 1.4 - 0.5 * t;
      rot = 90.0 + 50.0 * t;
      opacity = 1.0 - 0.15 * t;
    } else {
      final t = (morphProgress - 0.75) / 0.25;
      scale = 0.9 + 0.1 * t;
      rot = 140.0 + 40.0 * t;
      opacity = 0.85 + 0.15 * t;
    }

    if (opacity <= 0.0) return;

    canvas.save();
    canvas.translate(268, 248);
    canvas.rotate(rot * math.pi / 180.0);
    canvas.scale(scale, scale);

    final starPath = Path()
      ..moveTo(14, 0)
      ..lineTo(18, 10)
      ..lineTo(28, 14)
      ..lineTo(18, 18)
      ..lineTo(14, 28)
      ..lineTo(10, 18)
      ..lineTo(0, 14)
      ..lineTo(10, 10)
      ..close();

    // Center star at (0,0)
    canvas.translate(-14, -14);

    final starPaint = Paint()
      ..color = const Color(0xFFCAF0F8).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final starStroke = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(starPath, starPaint);
    canvas.drawPath(starPath, starStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KerkomLogoPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.orbitProgress != orbitProgress ||
        oldDelegate.idleProgress != idleProgress;
  }
}
