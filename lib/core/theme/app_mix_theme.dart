import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

import 'app_colors.dart';

class AppMixTokens {
  const AppMixTokens._();

  static const bg = ColorToken('bysiv.color.bg');
  static const bgPure = ColorToken('bysiv.color.bgPure');
  static const bgSubtle = ColorToken('bysiv.color.bgSubtle');
  static const glass = ColorToken('bysiv.color.glass');
  static const glassStrong = ColorToken('bysiv.color.glassStrong');
  static const glassBorder = ColorToken('bysiv.color.glassBorder');
  static const ink = ColorToken('bysiv.color.ink');
  static const inkDim = ColorToken('bysiv.color.inkDim');
  static const inkSub = ColorToken('bysiv.color.inkSub');
  static const inkSubSub = ColorToken('bysiv.color.inkSubSub');
  static const primary = ColorToken('bysiv.color.primary');
  static const primaryDeep = ColorToken('bysiv.color.primaryDeep');
  static const primarySoft = ColorToken('bysiv.color.primarySoft');
  static const primaryBorder = ColorToken('bysiv.color.primaryBorder');
  static const secondary = ColorToken('bysiv.color.secondary');

  static const spaceXs = SpaceToken('bysiv.space.xs');
  static const spaceSm = SpaceToken('bysiv.space.sm');
  static const spaceMd = SpaceToken('bysiv.space.md');
  static const spaceLg = SpaceToken('bysiv.space.lg');
  static const spaceXl = SpaceToken('bysiv.space.xl');

  static const radiusSm = RadiusToken('bysiv.radius.sm');
  static const radiusMd = RadiusToken('bysiv.radius.md');
  static const radiusLg = RadiusToken('bysiv.radius.lg');
  static const radiusXl = RadiusToken('bysiv.radius.xl');
  static const radiusPill = RadiusToken('bysiv.radius.pill');

  static const shadowSoft = BoxShadowToken('bysiv.shadow.soft');
  static const shadowMid = BoxShadowToken('bysiv.shadow.mid');
  static const shadowDeep = BoxShadowToken('bysiv.shadow.deep');
}

class AppMixTheme {
  const AppMixTheme._();

  static final colors = {
    AppMixTokens.bg: AppColors.bg,
    AppMixTokens.bgPure: AppColors.bgPure,
    AppMixTokens.bgSubtle: AppColors.bgSubtle,
    AppMixTokens.glass: AppColors.glass,
    AppMixTokens.glassStrong: AppColors.glassStrong,
    AppMixTokens.glassBorder: AppColors.glassBorder,
    AppMixTokens.ink: AppColors.ink,
    AppMixTokens.inkDim: AppColors.inkDim,
    AppMixTokens.inkSub: AppColors.inkSub,
    AppMixTokens.inkSubSub: AppColors.inkSubSub,
    AppMixTokens.primary: AppColors.primary,
    AppMixTokens.primaryDeep: AppColors.primaryDeep,
    AppMixTokens.primarySoft: AppColors.primarySoft,
    AppMixTokens.primaryBorder: AppColors.primaryBorder,
    AppMixTokens.secondary: AppColors.secondary,
  };

  static final spaces = {
    AppMixTokens.spaceXs: 4.0,
    AppMixTokens.spaceSm: 8.0,
    AppMixTokens.spaceMd: 16.0,
    AppMixTokens.spaceLg: 24.0,
    AppMixTokens.spaceXl: 32.0,
  };

  static final radii = {
    AppMixTokens.radiusSm: Radius.circular(12),
    AppMixTokens.radiusMd: Radius.circular(20),
    AppMixTokens.radiusLg: Radius.circular(28),
    AppMixTokens.radiusXl: Radius.circular(36),
    AppMixTokens.radiusPill: Radius.circular(999),
  };

  static final boxShadows = {
    AppMixTokens.shadowSoft: [
      BoxShadow(color: Color(0x0D14141E), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x0814141E), blurRadius: 2, offset: Offset(0, 1)),
    ],
    AppMixTokens.shadowMid: [
      BoxShadow(
        color: Color(0x1414141E),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: Color(0x0A14141E), blurRadius: 6, offset: Offset(0, 2)),
    ],
    AppMixTokens.shadowDeep: [
      BoxShadow(
        color: Color(0x1A14141E),
        blurRadius: 56,
        offset: Offset(0, 24),
      ),
      BoxShadow(color: Color(0x0D14141E), blurRadius: 12, offset: Offset(0, 4)),
    ],
  };
}
