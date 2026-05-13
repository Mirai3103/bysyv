import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        gradient: RadialGradient(
          center: Alignment(-0.78, -0.9),
          radius: 1.08,
          colors: [Color(0x1A4C5FEF), Color(0x00FCFBF8)],
          stops: [0, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(1, 0.35),
            radius: 1.0,
            colors: [Color(0x124C5FEF), Color(0x00FCFBF8)],
            stops: [0, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}
