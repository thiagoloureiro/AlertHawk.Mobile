import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class _Palette {
  const _Palette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.scaffold,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color scaffold;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
}

class AppTheme {
  static final ThemeData light = _build(const _Palette(
        brightness: Brightness.light,
        primary: Color(0xFF2563EB),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E3A8A),
        scaffold: Color(0xFFF8FAFC),
        surface: Color(0xFFFFFFFF),
        surfaceLow: Color(0xFFF1F5F9),
        surfaceHigh: Color(0xFFE2E8F0),
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF64748B),
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
        error: Color(0xFFDC2626),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF7F1D1D),
      ));

  static final ThemeData dark = _build(const _Palette(
        brightness: Brightness.dark,
        primary: Color(0xFF60A5FA),
        onPrimary: Color(0xFF0F172A),
        primaryContainer: Color(0xFF1E3A5F),
        onPrimaryContainer: Color(0xFFBFDBFE),
        scaffold: Color(0xFF111827),
        surface: Color(0xFF1F2937),
        surfaceLow: Color(0xFF1F2937),
        surfaceHigh: Color(0xFF374151),
        onSurface: Color(0xFFF9FAFB),
        onSurfaceVariant: Color(0xFF9CA3AF),
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF374151),
        error: Color(0xFFF87171),
        onError: Color(0xFF450A0A),
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFECACA),
      ));

  static final ThemeData githubDark = _build(const _Palette(
        brightness: Brightness.dark,
        primary: Color(0xFF58A6FF),
        onPrimary: Color(0xFF0D1117),
        primaryContainer: Color(0xFF1F3A5C),
        onPrimaryContainer: Color(0xFF79C0FF),
        scaffold: Color(0xFF0D1117),
        surface: Color(0xFF161B22),
        surfaceLow: Color(0xFF161B22),
        surfaceHigh: Color(0xFF30363D),
        onSurface: Color(0xFFC9D1D9),
        onSurfaceVariant: Color(0xFF8B949E),
        outline: Color(0xFF30363D),
        outlineVariant: Color(0xFF21262D),
        error: Color(0xFFF85149),
        onError: Colors.white,
        errorContainer: Color(0xFF490202),
        onErrorContainer: Color(0xFFFFC1BC),
      ));

  static final ThemeData monokai = _build(const _Palette(
        brightness: Brightness.dark,
        primary: Color(0xFFFD971F),
        onPrimary: Color(0xFF272822),
        primaryContainer: Color(0xFF5C4A2A),
        onPrimaryContainer: Color(0xFFFFD9A0),
        scaffold: Color(0xFF272822),
        surface: Color(0xFF3E3D32),
        surfaceLow: Color(0xFF3E3D32),
        surfaceHigh: Color(0xFF49483E),
        onSurface: Color(0xFFF8F8F2),
        onSurfaceVariant: Color(0xFFC0C0B4),
        outline: Color(0xFF49483E),
        outlineVariant: Color(0xFF3E3D32),
        error: Color(0xFFF92672),
        onError: Colors.white,
        errorContainer: Color(0xFF5C102E),
        onErrorContainer: Color(0xFFFFB1C8),
      ));

  static ThemeData _build(_Palette p) {
    final isDark = p.brightness == Brightness.dark;
    final baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseText).apply(
      bodyColor: p.onSurface,
      displayColor: p.onSurface,
    );

    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      secondaryContainer: p.primaryContainer,
      onSecondaryContainer: p.onPrimaryContainer,
      tertiary: p.primary,
      onTertiary: p.onPrimary,
      error: p.error,
      onError: p.onError,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      outline: p.outline,
      outlineVariant: p.outlineVariant,
      surfaceContainerLowest: p.scaffold,
      surfaceContainerLow: p.surfaceLow,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceHigh,
      surfaceContainerHighest: p.surfaceHigh,
      inverseSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1F2937),
      onInverseSurface: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      inversePrimary: p.primary,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final overlay = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: p.scaffold,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: p.scaffold,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    final radius = BorderRadius.circular(AppColors.radius);
    final radiusSm = BorderRadius.circular(AppColors.radiusSm);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.scaffold,
      canvasColor: p.scaffold,
      cardColor: p.surface,
      dividerColor: p.outlineVariant,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: p.scaffold,
        foregroundColor: p.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlay,
        iconTheme: IconThemeData(color: p.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: p.onSurface, size: 22),
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: -0.3,
          color: p.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.outline.withValues(alpha: 0.55)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceHigh.withValues(alpha: isDark ? 0.45 : 0.55),
        hintStyle: GoogleFonts.inter(color: p.onSurfaceVariant, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: p.onSurfaceVariant),
        prefixIconColor: p.onSurfaceVariant,
        suffixIconColor: p.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: p.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: p.onSurface,
          side: BorderSide(color: p.outline),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceHigh.withValues(alpha: isDark ? 0.6 : 0.8),
        selectedColor: p.primaryContainer,
        disabledColor: p.surfaceHigh,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: p.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXs),
          side: BorderSide(color: p.outline.withValues(alpha: 0.4)),
        ),
        side: BorderSide(color: p.outline.withValues(alpha: 0.4)),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceHigh : const Color(0xFF1F2937),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        elevation: 2,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.onSurfaceVariant.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: p.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        textStyle: GoogleFonts.inter(fontSize: 14, color: p.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.onSurfaceVariant,
        textColor: p.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: p.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: p.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
      dividerTheme: DividerThemeData(
        color: p.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onPrimary;
          return p.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.surfaceHigh;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(p.onPrimary),
        side: BorderSide(color: p.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.onSurfaceVariant;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(p.surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: radiusSm),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surfaceHigh : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),
      iconTheme: IconThemeData(color: p.onSurface, size: 22),
    );
  }
}
