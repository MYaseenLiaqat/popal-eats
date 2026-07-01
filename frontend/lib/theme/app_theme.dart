import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_extensions.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.lightAccent,
        primaryHover: AppColors.lightAccentHover,
        primaryPressed: AppColors.lightAccentPressed,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceLight: AppColors.lightSurfaceLight,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textOnSurface: AppColors.lightTextOnCard,
        border: AppColors.lightBorder,
        accentGradient: AppColors.lightAccentGradient,
        surfaceGradient: AppColors.lightSurfaceGradient,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.darkAccent,
        primaryHover: AppColors.darkAccentHover,
        primaryPressed: AppColors.darkAccentPressed,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceLight: AppColors.darkSurfaceLight,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textOnSurface: AppColors.darkTextPrimary,
        border: AppColors.darkBorder,
        accentGradient: AppColors.accentGradient,
        surfaceGradient: AppColors.surfaceGradient,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color primaryHover,
    required Color primaryPressed,
    required Color background,
    required Color surface,
    required Color surfaceLight,
    required Color textPrimary,
    required Color textSecondary,
    required Color textOnSurface,
    required Color border,
    required Gradient accentGradient,
    required Gradient surfaceGradient,
  }) {
    final isDark = brightness == Brightness.dark;
    // The accent is gold in both themes, and near-black text on gold is far
    // more legible (WCAG AA) than white — so gold buttons/chips use dark ink.
    const onAccent = AppColors.onAccentDark;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final accentSubtle =
        isDark ? AppColors.accentSubtle : AppColors.brandCardInner;
    final navBg = background;
    final navActive = primary;

    final scheme = isDark
        ? ColorScheme.dark(
            brightness: Brightness.dark,
            primary: primary,
            onPrimary: onAccent,
            primaryContainer: surfaceLight,
            onPrimaryContainer: textOnSurface,
            secondary: AppColors.brandGold,
            onSecondary: textOnSurface,
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            outline: border,
            outlineVariant: borderStrong,
            error: AppColors.error,
            onError: Colors.white,
          )
        : ColorScheme.light(
            brightness: Brightness.light,
            primary: primary,
            onPrimary: onAccent,
            primaryContainer: surfaceLight,
            onPrimaryContainer: AppColors.lightTextOnInner,
            secondary: AppColors.brandCardInner,
            onSecondary: AppColors.lightTextPrimary,
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            outline: border,
            outlineVariant: AppColors.lightBorder,
            error: AppColors.error,
            onError: Colors.white,
          );

    final borderSide = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.inputRadius),
      borderSide: BorderSide(color: borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
      extensions: const [PopalThemeExtension.defaults],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 24),
      ),
      textTheme: AppTypography.buildTextTheme(
        primary: textPrimary,
        secondary: textSecondary,
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 22),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : border,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onAccent,
          disabledBackgroundColor: surfaceLight,
          disabledForegroundColor: textSecondary,
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryHover.withValues(alpha: 0.15);
            }
            return null;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return surfaceLight;
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryHover;
            }
            return primary;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          minimumSize: const Size.fromHeight(AppColors.buttonHeight),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onAccent,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: TextStyle(
          color: isDark ? textSecondary : AppColors.lightTextOnInnerMuted,
        ),
        labelStyle: TextStyle(
          color: isDark ? textSecondary : AppColors.lightTextOnInner,
        ),
        prefixIconColor: isDark ? primary : AppColors.lightTextOnInner,
        suffixIconColor: isDark ? textSecondary : AppColors.lightTextOnInner,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: borderSide,
        enabledBorder: borderSide,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.inputRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return surfaceLight;
        }),
        checkColor: WidgetStatePropertyAll(onAccent),
        side: BorderSide(color: borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onAccent;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return surfaceLight;
        }),
        trackOutlineColor: WidgetStateProperty.all(borderStrong),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: accentSubtle,
        disabledColor: surfaceLight,
        labelStyle: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderStrong),
        ),
        checkmarkColor: primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: primary.withValues(alpha: 0.24),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            );
          }
          return TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: navActive, size: 26);
          }
          return IconThemeData(color: textSecondary, size: 26);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: navActive,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        contentTextStyle: TextStyle(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.cardRadius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: TextStyle(color: textPrimary),
        actionTextColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceLight,
        circularTrackColor: surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceLight,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.15),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderStrong),
        trackColor: WidgetStateProperty.all(surface),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(color: textPrimary),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: border),
            ),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        dividerColor: border,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: primary,
        textColor: onAccent,
      ),
    );
  }
}
