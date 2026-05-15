import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import 'app_button.dart';
import 'glass_panel.dart';

class AppBottomSheetOverlay extends StatelessWidget {
  const AppBottomSheetOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.children,
    this.maxHeightFactor = 0.78,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final List<Widget> children;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onBack,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(color: AppColors.ink.withValues(alpha: 0.25)),
            ),
          ),
        ).animate().fadeIn(duration: 220.ms),
        Align(
              alignment: Alignment.bottomCenter,
              child: GlassPanel(
                radius: 36,
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  40 + MediaQuery.paddingOf(context).bottom,
                ),
                strong: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.sizeOf(context).height * maxHeightFactor,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        AppButton(
                          label: 'Back',
                          icon: LucideIcons.chevronLeft,
                          onPressed: onBack,
                          variant: AppButtonVariant.ghost,
                          fullWidth: false,
                          height: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.inkDim,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .slideY(begin: 1, duration: 550.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 240.ms),
      ],
    );
  }
}
