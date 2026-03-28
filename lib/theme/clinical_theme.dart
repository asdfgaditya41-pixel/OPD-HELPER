import 'package:flutter/material.dart';

import 'clinical_tokens.dart';

class ClinicalTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: ClinicalColors.primary,
      onPrimary: ClinicalColors.onPrimary,
      primaryContainer: ClinicalColors.primaryContainer,
      onPrimaryContainer: ClinicalColors.onPrimary,
      secondary: ClinicalColors.onSecondaryContainer,
      onSecondary: ClinicalColors.onPrimary,
      secondaryContainer: ClinicalColors.secondaryContainer,
      onSecondaryContainer: ClinicalColors.onSecondaryContainer,
      tertiary: ClinicalColors.tertiary,
      onTertiary: ClinicalColors.onPrimary,
      tertiaryContainer: ClinicalColors.tertiaryContainer,
      onTertiaryContainer: ClinicalColors.onTertiaryContainer,
      error: ClinicalColors.tertiary,
      onError: ClinicalColors.onPrimary,
      errorContainer: ClinicalColors.tertiaryContainer,
      onErrorContainer: ClinicalColors.onTertiaryContainer,
      surface: ClinicalColors.surface,
      onSurface: ClinicalColors.onSurface,
      surfaceTint: ClinicalColors.surfaceTint,
      outlineVariant: ClinicalColors.outlineVariant,
    );

    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(letterSpacing: 0.2),
      labelMedium: baseTextTheme.labelMedium?.copyWith(letterSpacing: 0.2),
    );

    final ghostOutline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(ClinicalRadii.button),
      borderSide: BorderSide(
        color: ClinicalColors.outlineVariant.withOpacity(0.2),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ClinicalColors.surface,
      textTheme: textTheme.apply(
        bodyColor: ClinicalColors.onSurface,
        displayColor: ClinicalColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ClinicalColors.surface,
        foregroundColor: ClinicalColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ClinicalColors.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: ClinicalColors.surfaceContainerLowest,
        shadowColor: ClinicalColors.ambientShadow,
        surfaceTintColor: ClinicalColors.surfaceTint.withOpacity(0.05),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.card),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ClinicalColors.surfaceContainerLowest.withOpacity(0.8),
        surfaceTintColor: ClinicalColors.surfaceTint.withOpacity(0.05),
        shadowColor: ClinicalColors.ambientShadow,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ClinicalColors.surfaceContainerLowest.withOpacity(0.8),
        surfaceTintColor: ClinicalColors.surfaceTint.withOpacity(0.05),
        shadowColor: ClinicalColors.ambientShadow,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ClinicalRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ClinicalColors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ClinicalColors.surfaceContainerLowest,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.card),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: 0,
        thickness: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ClinicalColors.surfaceContainerLow,
        disabledColor: ClinicalColors.surfaceContainerLow,
        selectedColor: ClinicalColors.primary.withOpacity(0.12),
        side: BorderSide(color: ClinicalColors.outlineVariant.withOpacity(0.0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: ClinicalColors.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: ClinicalColors.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, ClinicalSpacing.touchTargetMinHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.button),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const WidgetStatePropertyAll(ClinicalColors.primary),
          foregroundColor: const WidgetStatePropertyAll(
            ClinicalColors.onPrimary,
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, ClinicalSpacing.touchTargetMinHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.button),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const WidgetStatePropertyAll(ClinicalColors.primary),
          foregroundColor: const WidgetStatePropertyAll(
            ClinicalColors.onPrimary,
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, ClinicalSpacing.touchTargetMinHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.button),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(ClinicalColors.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(
              ClinicalSpacing.touchTargetMinHeight,
              ClinicalSpacing.touchTargetMinHeight,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClinicalRadii.button),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClinicalColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: ghostOutline,
        enabledBorder: ghostOutline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.button),
          borderSide: BorderSide(
            color: ClinicalColors.primary.withOpacity(0.6),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.button),
          borderSide: BorderSide(
            color: ClinicalColors.tertiary.withOpacity(0.6),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicalRadii.button),
          borderSide: BorderSide(
            color: ClinicalColors.tertiary.withOpacity(0.8),
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: ClinicalColors.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: ClinicalColors.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ClinicalColors.primary,
        selectionColor: Color(0x33005DAC),
        selectionHandleColor: ClinicalColors.primary,
      ),
    );
  }
}
