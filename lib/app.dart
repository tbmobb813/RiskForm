import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/app_router.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Surfaces (3-depth system — no elevation shadows, border-based separation)
  static const bg = Color(0xFF0C0D10);
  static const surface1 = Color(0xFF13151A);
  static const surface2 = Color(0xFF1A1D25);
  static const border = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // Brand
  static const primary = Color(0xFF7C3AED); // Violet-600
  static const primaryLight = Color(0xFF8B5CF6); // Violet-500 (hover/active)
  static const primaryDim = Color(0x337C3AED); // Violet-600 @ 20%

  // Signal (amber — attention, setup highlight)
  static const signal = Color(0xFFF59E0B); // Amber-400
  static const signalDim = Color(0x33F59E0B); // Amber @ 20%

  // P&L
  static const profit = Color(0xFF10B981); // Emerald-500
  static const loss = Color(0xFFF43F5E); // Rose-500
  static const profitDim = Color(0x2210B981);
  static const lossDim = Color(0x22F43F5E);

  // Text hierarchy
  static const textPrimary = Color(0xFFF1F5F9); // Slate-100
  static const textSecondary = Color(0xFF94A3B8); // Slate-400
  static const textMuted = Color(0xFF475569); // Slate-600
}

// ── Typography ────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  // Sora — display & headlines
  static TextStyle display(double size) => GoogleFonts.sora(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Plus Jakarta Sans — body copy
  static TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: AppColors.textPrimary,
      );

  // JetBrains Mono — numbers, prices, tickers
  static TextStyle mono(double size, {Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

// ── Gradients & glow ──────────────────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  // Subtle violet-tinted wash for hero surfaces.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDim, Colors.transparent],
  );

  // Soft colored glow, e.g. behind badges, banners, and primary actions.
  static List<BoxShadow> glow(
    Color color, {
    double blur = 16,
    double opacity = 0.35,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 1,
    ),
  ];

  // Fade-to-transparent fill for chart areas under a line.
  static LinearGradient chartFill(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
  );
}

// ── Strategy color taxonomy ───────────────────────────────────────────────────

class StrategyTheme {
  StrategyTheme._();

  static const _violet = AppColors.primary;
  static const _amber = AppColors.signal;
  static const _rose = AppColors.loss; // Color(0xFFF43F5E)
  static const _teal = Color(0xFF14B8A6);
  static const _sky = Color(0xFF38BDF8);

  static const Map<String, _StratMeta> _map = {
    'csp': _StratMeta(color: _violet, badge: 'CSP', category: 'Income'),
    'cc': _StratMeta(color: _amber, badge: 'CC', category: 'Income'),
    'credit_spread': _StratMeta(
      color: _rose,
      badge: 'Spread',
      category: 'Income',
    ),
    'debit_spread': _StratMeta(
      color: _rose,
      badge: 'Spread',
      category: 'Speculation',
    ),
    'iron_condor': _StratMeta(color: _teal, badge: 'IC', category: 'Neutral'),
    'long_call': _StratMeta(
      color: _sky,
      badge: 'Long Call',
      category: 'Speculation',
    ),
    'long_put': _StratMeta(
      color: AppColors.primaryLight,
      badge: 'Long Put',
      category: 'Speculation',
    ),
    'protective_put': _StratMeta(
      color: _amber,
      badge: 'Hedge',
      category: 'Hedging',
    ),
    'collar': _StratMeta(color: _amber, badge: 'Collar', category: 'Hedging'),
  };

  static Color color(String? id) => _map[id]?.color ?? AppColors.primaryLight;
  static String badge(String? id) => _map[id]?.badge ?? '—';
  static String category(String? id) => _map[id]?.category ?? 'Strategy';
}

class _StratMeta {
  final Color color;
  final String badge;
  final String category;
  const _StratMeta({
    required this.color,
    required this.badge,
    required this.category,
  });
}

// ── App ───────────────────────────────────────────────────────────────────────

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RiskForm',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    final bodyFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: AppColors.surface1,
            onSurface: AppColors.textPrimary,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.signal,
            onSecondary: AppColors.bg,
            error: AppColors.loss,
            onError: Colors.white,
          ).copyWith(
            surfaceContainerHighest: AppColors.surface2,
            outline: AppColors.border,
          ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: bodyFont,
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface1,
        indicatorColor: AppColors.primaryDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.plusJakartaSans(fontSize: 11);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            );
          }
          return base.copyWith(color: AppColors.textMuted);
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        height: 68,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface1,
        indicatorColor: AppColors.primaryDim,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryLight,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textMuted,
          size: 24,
        ),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textMuted,
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.primaryDim,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.sora(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
