import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final foreground = _foregroundColor(enabled);
    final borderRadius = BorderRadius.circular(999);

    Widget button = AnimatedScale(
      scale: _pressed && enabled ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: _backgroundColor(enabled),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: borderRadius,
          splashColor: _splashColor(),
          highlightColor: _highlightColor(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: _border(enabled),
              boxShadow: _shadows(enabled),
            ),
            child: SizedBox(
              height: widget.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: widget.fullWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: foreground, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: widget.variant == AppButtonVariant.ghost
                              ? 14
                              : 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Color _backgroundColor(bool enabled) {
    if (!enabled) return AppColors.inkSubSub;
    return switch (widget.variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => AppColors.glassStrong,
      AppButtonVariant.ghost => Colors.transparent,
    };
  }

  Color _foregroundColor(bool enabled) {
    if (!enabled) return AppColors.inkSub;
    return switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => AppColors.ink,
      AppButtonVariant.ghost => AppColors.primary,
    };
  }

  Border? _border(bool enabled) {
    if (!enabled || widget.variant != AppButtonVariant.secondary) return null;
    return Border.all(color: AppColors.glassBorder);
  }

  List<BoxShadow>? _shadows(bool enabled) {
    if (!enabled) return null;
    if (widget.variant == AppButtonVariant.primary) {
      return const [
        BoxShadow(
          color: Color(0x334C5FEF),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
    }
    if (widget.variant == AppButtonVariant.secondary) {
      return const [
        BoxShadow(
          color: Color(0x0D14141E),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ];
    }
    return null;
  }

  Color _splashColor() {
    return switch (widget.variant) {
      AppButtonVariant.primary => Colors.white.withValues(alpha: 0.20),
      AppButtonVariant.secondary => AppColors.primary.withValues(alpha: 0.10),
      AppButtonVariant.ghost => AppColors.primary.withValues(alpha: 0.10),
    };
  }

  Color _highlightColor() {
    return switch (widget.variant) {
      AppButtonVariant.primary => Colors.white.withValues(alpha: 0.10),
      AppButtonVariant.secondary => AppColors.primary.withValues(alpha: 0.06),
      AppButtonVariant.ghost => AppColors.primary.withValues(alpha: 0.06),
    };
  }
}
