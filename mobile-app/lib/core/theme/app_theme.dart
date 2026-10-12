import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvasLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.actionAccent,
        onPrimary: AppColors.canvasLight,
        secondary: AppColors.inkMuted,
        onSecondary: AppColors.canvasLight,
        error: AppColors.dangerText,
        onError: AppColors.canvasLight,
        surface: AppColors.canvasLight,
        onSurface: AppColors.inkPrimary,
        outline: AppColors.borderNeutral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasLight,
        foregroundColor: AppColors.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.inkPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.inkPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.canvasLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
          side: const BorderSide(
            color: AppColors.hairline,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionAccent,
          foregroundColor: AppColors.canvasLight,
          disabledBackgroundColor: AppColors.borderNeutral,
          disabledForegroundColor: AppColors.inkMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, AppDimensions.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkPrimary,
          backgroundColor: AppColors.canvasLight,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimensions.minTouchTarget),
          side: const BorderSide(
            color: AppColors.borderNeutral,
            width: AppDimensions.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvasLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.borderNeutral,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.borderNeutral,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.actionAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.dangerText,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.dangerText,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.inkMuted,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.inkMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: AppDimensions.borderWidth,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.actionAccent,
        selectionColor: AppColors.orangeBorder,
        selectionHandleColor: AppColors.actionAccent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.actionAccent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvasLight,
        indicatorColor: AppColors.orangeTint,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.actionAccent);
          }
          return const IconThemeData(color: AppColors.inkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.actionAccent,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.inkPrimary,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.inkPrimary,
          height: 1.33,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.inkPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.inkPrimary,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.inkMuted,
          height: 1.33,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.inkPrimary,
        ),
      ),
    );
  }
}

class AppTextStyle {
  AppTextStyle._();

  // Tabular Font for Currency, Nominal, GPS Coordinates, and Time
  static const TextStyle tabularData = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle currency({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.inkPrimary,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle time({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.inkPrimary,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle coordinates({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.inkMuted,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
