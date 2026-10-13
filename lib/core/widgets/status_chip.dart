import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum StatusChipColor { green, red, amber, lime }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipColor color;

  const StatusChip({
    super.key,
    required this.label,
    this.color = StatusChipColor.lime,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color bgColor;
    Color textColor;

    switch (color) {
      case StatusChipColor.green:
        dotColor = AppColors.green;
        bgColor = AppColors.greenSoft;
        textColor = AppColors.green;
        break;
      case StatusChipColor.red:
        dotColor = AppColors.red;
        bgColor = AppColors.redSoft;
        textColor = AppColors.red;
        break;
      case StatusChipColor.amber:
        dotColor = AppColors.amber;
        bgColor = AppColors.amberSoft;
        textColor = AppColors.amber;
        break;
      case StatusChipColor.lime:
        dotColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
