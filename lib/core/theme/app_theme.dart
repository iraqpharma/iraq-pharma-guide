import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ── Light text theme ──────────────────────────────────────────────────────
  static TextTheme get _lightTextTheme =>
      GoogleFonts.ibmPlexSansArabicTextTheme(
        const TextTheme(
          titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold,  color: Colors.white),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,  color: AppColors.textPrimary),
          titleSmall:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
          bodyLarge:   TextStyle(fontSize: 15, color: AppColors.textPrimary),
          bodyMedium:  TextStyle(fontSize: 14, color: AppColors.textPrimary),
          bodySmall:   TextStyle(fontSize: 12, color: AppColors.textSecondary),
          labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
          labelMedium: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          labelSmall:  TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      );

  // ── Dark text theme ───────────────────────────────────────────────────────
  static TextTheme get _darkTextTheme =>
      GoogleFonts.ibmPlexSansArabicTextTheme(
        const TextTheme(
          titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold,  color: Colors.white),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,  color: AppColors.darkText),
          titleSmall:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600,  color: AppColors.darkText),
          bodyLarge:   TextStyle(fontSize: 15, color: AppColors.darkText),
          bodyMedium:  TextStyle(fontSize: 14, color: AppColors.darkText),
          bodySmall:   TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
          labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600,  color: AppColors.darkText),
          labelMedium: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
          labelSmall:  TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary:   AppColors.primary,
        secondary: AppColors.accent,
        surface:   AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme:        _lightTextTheme,
      primaryTextTheme: _lightTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.cardWhite,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardWhite,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withOpacity(0.4)
              : null),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(
            color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness:              Brightness.dark,
      // Brand primary — slightly lighter teal for dark backgrounds
      primary:                 AppColors.accent,
      onPrimary:               Colors.white,
      primaryContainer:        AppColors.primaryDark,
      onPrimaryContainer:      AppColors.primaryLight,
      // Secondary
      secondary:               AppColors.accent,
      onSecondary:             Colors.white,
      secondaryContainer:      Color(0xFF004D40),
      onSecondaryContainer:    AppColors.primaryLight,
      // Surfaces
      surface:                 AppColors.darkCard,
      onSurface:               AppColors.darkText,
      surfaceContainerHighest: AppColors.darkSurface,
      onSurfaceVariant:        AppColors.darkTextMuted,
      // Error
      error:                   Color(0xFFEF9A9A),
      onError:                 Color(0xFF1A1A1A),
      errorContainer:          Color(0xFF4E1A1A),
      onErrorContainer:        Color(0xFFFFDAD4),
      // Outline
      outline:                 AppColors.darkDivider,
      outlineVariant:          AppColors.darkDivider,
      // Inverse
      inverseSurface:          AppColors.darkText,
      onInverseSurface:        AppColors.darkBg,
      inversePrimary:          AppColors.primaryDark,
      // Scrim
      scrim:                   Colors.black54,
      shadow:                  Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness:             Brightness.dark,
      colorScheme:            colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
    );

    return base.copyWith(
      textTheme:        _darkTextTheme,
      primaryTextTheme: _darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkDivider),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkElevated,
        side: const BorderSide(color: AppColors.darkDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12, color: AppColors.darkText, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputFill,
        hintStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14, color: AppColors.darkTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.darkTextMuted,
        suffixIconColor: AppColors.darkTextMuted,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.darkTextMuted,
        collapsedIconColor: AppColors.darkTextMuted,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: AppColors.darkText,
        collapsedTextColor: AppColors.darkText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          textStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkTextMuted,
        textColor: AppColors.darkText,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextMuted),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : null),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent.withOpacity(0.4)
              : AppColors.darkElevated),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.darkElevated),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.darkTextMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.darkTextMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.darkTextMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            color: s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.darkTextMuted,
            fontSize: 12,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14, color: AppColors.darkTextMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevated,
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(
            color: AppColors.darkText, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.darkElevated,
        elevation: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: AppColors.darkText),
      ),
    );
  }
}
