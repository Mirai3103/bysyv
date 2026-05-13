import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

import '../../../core/theme/app_colors.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .borderRounded(radius)
          .color(strong ? AppColors.glassStrong : AppColors.glass)
          .border(
            BoxBorderMix.all(
              BorderSideMix(color: AppColors.glassBorder, width: 1),
            ),
          )
          .shadows([
            BoxShadowMix(
              color: const Color(0x0D14141E),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]),
      child: Padding(padding: padding, child: child),
    );
  }
}
