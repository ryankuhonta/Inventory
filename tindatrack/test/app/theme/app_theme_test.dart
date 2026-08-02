import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/app/theme/app_typography.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

void main() {
  test('retains every approved color token', () {
    expect(AppColors.background, const Color(0xFFF8FAF7));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.surfaceMuted, const Color(0xFFEEF3EE));
    expect(AppColors.textPrimary, const Color(0xFF172018));
    expect(AppColors.textSecondary, const Color(0xFF5E6B60));
    expect(AppColors.primary, const Color(0xFF2E7D4F));
    expect(AppColors.primaryPressed, const Color(0xFF24643F));
    expect(AppColors.success, const Color(0xFF2E7D4F));
    expect(AppColors.warning, const Color(0xFFB7791F));
    expect(AppColors.warningSurface, const Color(0xFFFFF7E0));
    expect(AppColors.danger, const Color(0xFFB42318));
    expect(AppColors.dangerSurface, const Color(0xFFFDECEC));
    expect(AppColors.border, const Color(0xFFDDE5DD));
  });

  test('retains approved spacing and dimensions', () {
    const spacing = AppSpacing.standard;
    expect(spacing.xs, 4);
    expect(spacing.sm, 8);
    expect(spacing.md, 16);
    expect(spacing.lg, 24);
    expect(spacing.xl, 32);
    expect(spacing.copyWith(md: 20).md, 20);
    expect(
      spacing
          .lerp(const AppSpacing(xs: 8, sm: 16, md: 24, lg: 32, xl: 40), 0.5)
          .xs,
      6,
    );
    expect(AppDimensions.radiusSmall, 6);
    expect(AppDimensions.radiusMedium, 8);
    expect(AppDimensions.radiusLarge, 12);
    expect(AppDimensions.componentRadius, 8);
    expect(AppDimensions.statusPillRadius, 999);
    expect(AppDimensions.minimumTapTarget, 48);
  });

  test('configures exact typography and Material 3 semantic colors', () {
    final theme = AppTheme.light;
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.colorScheme.surfaceContainer, AppColors.surfaceMuted);
    expect(theme.colorScheme.onSurface, AppColors.textPrimary);
    expect(theme.colorScheme.onSurfaceVariant, AppColors.textSecondary);
    expect(theme.colorScheme.error, AppColors.danger);
    expect(theme.colorScheme.errorContainer, AppColors.dangerSurface);
    expect(theme.colorScheme.outline, AppColors.border);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.extension<AppSpacing>(), AppSpacing.standard);
    const text = AppTypography.textTheme;
    expect(text.displayLarge?.fontSize, 28);
    expect(text.displayLarge?.fontWeight, FontWeight.w700);
    expect(text.titleLarge?.fontSize, 20);
    expect(text.titleLarge?.fontWeight, FontWeight.w700);
    expect(text.titleMedium?.fontSize, 16);
    expect(text.titleMedium?.fontWeight, FontWeight.w700);
    expect(text.bodyMedium?.fontSize, 14);
    expect(text.bodyMedium?.fontWeight, FontWeight.w400);
    expect(text.labelLarge?.fontSize, 12);
    expect(text.labelLarge?.fontWeight, FontWeight.w600);
  });

  test('configures component radii, minimum sizes, and pressed color', () {
    final theme = AppTheme.light;
    final filledStyle = theme.filledButtonTheme.style!;
    expect(identical(AppTheme.light, AppTheme.light), isTrue);
    expect(
      filledStyle.minimumSize?.resolve(<WidgetState>{}),
      const Size(48, 48),
    );
    expect(
      filledStyle.backgroundColor?.resolve(<WidgetState>{WidgetState.pressed}),
      AppColors.primaryPressed,
    );
    expect(
      filledStyle.backgroundColor?.resolve(<WidgetState>{
        WidgetState.disabled,
      }),
      isNull,
    );
    expect(
      filledStyle.textStyle?.resolve(<WidgetState>{}),
      AppTypography.textTheme.labelLarge,
    );
    expect(
      theme.navigationBarTheme.labelTextStyle?.resolve(<WidgetState>{}),
      AppTypography.textTheme.labelLarge,
    );
    final buttonShape =
        filledStyle.shape!.resolve(<WidgetState>{})! as RoundedRectangleBorder;
    expect(buttonShape.borderRadius, BorderRadius.circular(8));
    final inputBorder =
        theme.inputDecorationTheme.border! as OutlineInputBorder;
    expect(inputBorder.borderRadius, BorderRadius.circular(8));
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, BorderRadius.circular(8));
  });
}
