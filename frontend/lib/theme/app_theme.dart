import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_extensions.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentSubtle,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      error: AppColors.error,
      onError: AppColors.onAccent,
    );

    final borderSide = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
      extensions: const [PopalThemeExtension.defaults],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          elevation: 0,
          shadowColor: AppColors.accent.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.accentPressed.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.accentHover.withValues(alpha: 0.15);
            }
            return null;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceLight;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.accentPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.accentHover;
            }
            return AppColors.accent;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: borderSide,
        enabledBorder: borderSide,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.inputRadius),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.surfaceLight;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onAccent),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onAccent;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.surfaceLight;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.borderStrong),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.textSecondary;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentSubtle,
        disabledColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: AppColors.accent),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        checkmarkColor: AppColors.accent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.cardRadius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceLight,
        circularTrackColor: AppColors.surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.15),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.borderStrong),
        trackColor: WidgetStateProperty.all(AppColors.surface),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
        dividerColor: AppColors.border,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.accent,
        textColor: AppColors.onAccent,
      ),
    );
  }
}
