// Member names describe the small, class-documented presentation API.
// ignore_for_file: public_member_api_docs

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Theme-provided spacing scale shared across app and feature presentation.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  /// Creates a spacing scale.
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Approved MVP spacing scale.
  static const standard = AppSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  /// Reads spacing from the active theme, with approved values as fallback.
  static AppSpacing of(BuildContext context) {
    return Theme.of(context).extension<AppSpacing>() ?? standard;
  }

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}
