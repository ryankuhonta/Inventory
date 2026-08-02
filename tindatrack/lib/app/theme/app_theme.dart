import 'package:flutter/material.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/app/theme/app_typography.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Root application theme.
abstract final class AppTheme {
  /// Approved light Material 3 theme for the MVP.
  static final ThemeData light = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ).copyWith(
          primary: AppColors.primary,
          surface: AppColors.surface,
          surfaceContainer: AppColors.surfaceMuted,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.danger,
          errorContainer: AppColors.dangerSurface,
          outline: AppColors.border,
        );
    const componentBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppDimensions.componentRadius),
      ),
    );
    const minimumActionSize = Size(
      AppDimensions.minimumTapTarget,
      AppDimensions.minimumTapTarget,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: const <ThemeExtension<dynamic>>[AppSpacing.standard],
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.componentRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minimumActionSize),
          shape: const WidgetStatePropertyAll(componentBorder),
          textStyle: WidgetStatePropertyAll(
            AppTypography.textTheme.labelLarge,
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(minimumActionSize),
          shape: WidgetStatePropertyAll(componentBorder),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(minimumActionSize),
          shape: WidgetStatePropertyAll(componentBorder),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(minimumActionSize),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        constraints: BoxConstraints(minHeight: AppDimensions.minimumTapTarget),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.componentRadius),
          ),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.componentRadius),
          ),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
