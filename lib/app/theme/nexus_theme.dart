import 'package:flutter/material.dart';

/// NexusPay design system.
///
/// Concept: dark-first fintech/ops dashboard — the aesthetic of a
/// professional trading terminal applied to construction payroll.
/// Dense, information-rich, high-contrast, intentional.
///
/// NOT generic Material 3 defaults. Every value here is a deliberate
/// choice for this product and this audience.
abstract class NexusColors {
  // -- Backgrounds (dark-first) --
  static const base = Color(0xFF0E0F11);       // page background
  static const surface = Color(0xFF1A1D23);    // card / panel
  static const surfaceHigh = Color(0xFF21252E); // elevated surface
  static const overlay = Color(0xFF2A2D35);    // hover / selected row

  // -- Borders --
  static const border = Color(0xFF2A2D35);
  static const borderSubtle = Color(0xFF1E2128);

  // -- Text --
  static const textPrimary = Color(0xFFF0F2F5);
  static const textSecondary = Color(0xFF8B95A5);
  static const textMuted = Color(0xFF4E5566);

  // -- Primary: electric indigo --
  static const primary = Color(0xFF4F6EF7);
  static const primaryDim = Color(0xFF1E2E6B);
  static const primaryText = Color(0xFF8FA8FF);

  // -- Accent: amber — used on financial figures, OT, warnings --
  static const amber = Color(0xFFF5A623);
  static const amberDim = Color(0xFF3D2800);
  static const amberText = Color(0xFFFFCB72);

  // -- Semantic --
  static const positive = Color(0xFF22C87A);   // active, paid, approved
  static const positiveDim = Color(0xFF0D2E1C);
  static const negative = Color(0xFFE84646);   // error, deactivated, overdue
  static const negativeDim = Color(0xFF2E0D0D);
  static const warning = Color(0xFFF5A623);
  static const cyan = Color(0xFF36C5F0);       // attendance module accent
  static const cyanDim = Color(0xFF0D2A36);

  // -- Module accent colours (used on section-header left-border rule) --
  static const moduleEmployee = primary;
  static const moduleProject = cyan;
  static const moduleSupervisor = Color(0xFFAD7BFF); // violet
  static const moduleAssignment = Color(0xFF36C5F0);
  static const modulePayroll = amber;
  static const moduleAttendance = positive;
}

abstract class NexusRadius {
  static const none = Radius.circular(0);
  static const sm = BorderRadius.all(Radius.circular(4));
  static const md = BorderRadius.all(Radius.circular(6));
  static const chip = BorderRadius.all(Radius.circular(20));
  static const dialog = BorderRadius.all(Radius.circular(12));
  static const sheet = BorderRadius.vertical(top: Radius.circular(16));
}

abstract class NexusSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Google Fonts are not imported as a package here to avoid adding a
/// pub dependency. Instead, declare the families; the project's
/// pubspec.yaml should add google_fonts or include the font files.
/// Fallback to system sans-serif if unavailable.
abstract class NexusTypography {

  static const displayLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: NexusColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const displayMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: NexusColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const headingSection = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: NexusColors.textSecondary,
    letterSpacing: 0.8,
    height: 1.4,
  );

  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: NexusColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: NexusColors.textPrimary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: NexusColors.textSecondary,
    height: 1.4,
  );

  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: NexusColors.textMuted,
    letterSpacing: 0.6,
    height: 1.3,
  );

  // Money / hours figures always tabular
  static TextStyle money({
    double fontSize = 15,
    FontWeight weight = FontWeight.w600,
    Color color = NexusColors.amberText,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.3,
      );
}

class NexusTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: NexusColors.base,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: NexusColors.primary,
        onPrimary: NexusColors.textPrimary,
        secondary: NexusColors.amber,
        onSecondary: NexusColors.base,
        surface: NexusColors.surface,
        onSurface: NexusColors.textPrimary,
        error: NexusColors.negative,
        onError: NexusColors.textPrimary,
        outline: NexusColors.border,
        outlineVariant: NexusColors.borderSubtle,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: NexusColors.surface,
        foregroundColor: NexusColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: NexusColors.textSecondary),
      ),

      // Navigation Rail (desktop)
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: NexusColors.surface,
        selectedIconTheme: IconThemeData(color: NexusColors.primary, size: 20),
        unselectedIconTheme:
            IconThemeData(color: NexusColors.textMuted, size: 20),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: NexusColors.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: NexusColors.textMuted,
        ),
        indicatorColor: NexusColors.primaryDim,
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4))),
        minWidth: 64,
        minExtendedWidth: 200,
      ),

      // Navigation Bar (mobile bottom)
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: NexusColors.surface,
        indicatorColor: NexusColors.primaryDim,
        iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: NexusColors.textSecondary, size: 20)),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: NexusColors.textSecondary,
        )),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: NexusColors.surface,
        width: 240,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: NexusColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // Card
      cardTheme: CardThemeData(
        color: NexusColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: NexusRadius.sm,
          side: const BorderSide(color: NexusColors.border),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexusColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: NexusRadius.sm,
          borderSide: const BorderSide(color: NexusColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NexusRadius.sm,
          borderSide: const BorderSide(color: NexusColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NexusRadius.sm,
          borderSide: const BorderSide(color: NexusColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: NexusRadius.sm,
          borderSide: const BorderSide(color: NexusColors.negative),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: NexusColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: NexusColors.textMuted,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),

      // Filled button (primary action)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NexusColors.primary,
          foregroundColor: NexusColors.textPrimary,
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          shape:
              const RoundedRectangleBorder(borderRadius: NexusRadius.sm),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NexusColors.textSecondary,
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
          shape:
              const RoundedRectangleBorder(borderRadius: NexusRadius.sm),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusColors.primary,
          side: const BorderSide(color: NexusColors.primary),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
          shape:
              const RoundedRectangleBorder(borderRadius: NexusRadius.sm),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NexusColors.primary,
        foregroundColor: NexusColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: NexusRadius.sm),
        elevation: 0,
      ),

      // Chips (filter)
      chipTheme: ChipThemeData(
        backgroundColor: NexusColors.surfaceHigh,
        selectedColor: NexusColors.primaryDim,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: NexusColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: NexusColors.primaryText,
        ),
        side: const BorderSide(color: NexusColors.border),
        shape: const RoundedRectangleBorder(borderRadius: NexusRadius.chip),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: NexusColors.surface,
        shape: RoundedRectangleBorder(borderRadius: NexusRadius.dialog),
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: NexusColors.textSecondary,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NexusColors.surfaceHigh,
        contentTextStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: NexusColors.textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: NexusRadius.sm),
        behavior: SnackBarBehavior.floating,
      ),

      // PopupMenu
      popupMenuTheme: const PopupMenuThemeData(
        color: NexusColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: NexusRadius.sm),
        textStyle:
            TextStyle(fontFamily: 'Inter', fontSize: 13, color: NexusColors.textPrimary),
        elevation: 4,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.transparent,
        textColor: NexusColors.textPrimary,
        iconColor: NexusColors.textMuted,
        dense: true,
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NexusColors.surface,
        modalBackgroundColor: NexusColors.surface,
        shape: RoundedRectangleBorder(borderRadius: NexusRadius.sheet),
        dragHandleColor: NexusColors.border,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: NexusTypography.displayLarge,
        displayMedium: NexusTypography.displayMedium,
        headlineSmall: NexusTypography.displayMedium,
        titleLarge: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        bodyLarge: NexusTypography.bodyLarge,
        bodyMedium: NexusTypography.bodyMedium,
        bodySmall: NexusTypography.bodySmall,
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: NexusColors.textSecondary,
        ),
        labelSmall: NexusTypography.label,
      ),
    );
  }
}
