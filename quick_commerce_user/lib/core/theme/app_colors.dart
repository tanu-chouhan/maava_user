import 'package:flutter/material.dart';

/// Suvio Quick brand palette.
///
/// The mart identity is a deep harvest green on near-white surfaces, with a
/// brighter green reserved for highlights — fresh + premium, and high-contrast
/// at badge sizes. Each flavour carries its own plate colours so nothing in the
/// widget layer has to special-case a particular brand.
enum AppThemeFlavor {
  /// The mart palette: a deep harvest green with a brighter green highlight,
  /// on near-white surfaces. This is the default the app ships with.
  harvest(
    label: 'Harvest Green',
    seed: Color(0xFF1B7A32),
    accent: Color(0xFF2E9E4A),
    plate: Color(0xFF1B7A32),
    plateSoft: Color(0xFFEDF5E3),
    plateDark: Color(0xFF17301F),
    plateSoftDark: Color(0xFF13251A),
  ),
  appzeto(
    label: 'Appzeto Yellow',
    seed: Color(0xFFFFD400),
    accent: Color(0xFF16A34A),
    plate: Color(0xFFFFD400),
    plateSoft: Color(0xFFFFF1C5),
    plateDark: Color(0xFF3A3416),
    plateSoftDark: Color(0xFF2B2712),
  ),
  indigo(
    label: 'Suvio Indigo',
    seed: Color(0xFF4338CA),
    accent: Color(0xFFFF7A59),
    plate: Color(0xFF4338CA),
    plateSoft: Color(0xFFE6E4F8),
    plateDark: Color(0xFF1E1B36),
    plateSoftDark: Color(0xFF191730),
  ),
  sunset(
    label: 'Suvio Sunset',
    seed: Color(0xFFE0533D),
    accent: Color(0xFF1F9C8A),
    plate: Color(0xFFE0533D),
    plateSoft: Color(0xFFFBE6E2),
    plateDark: Color(0xFF33201C),
    plateSoftDark: Color(0xFF2B1B18),
  );

  const AppThemeFlavor({
    required this.label,
    required this.seed,
    required this.accent,
    required this.plate,
    required this.plateSoft,
    required this.plateDark,
    required this.plateSoftDark,
  });

  final String label;
  final Color seed;
  final Color accent;

  /// The saturated brand plate — header, badges, the add pill.
  final Color plate;

  /// The tinted plate behind hero and promo cards.
  final Color plateSoft;

  final Color plateDark;
  final Color plateSoftDark;

  /// Ink that stays legible on [plate], whichever end of the scale it sits at.
  Color get onPlate => plate.computeLuminance() > 0.5
      ? AppColors.lightTextPrimary
      : AppColors.lightSurface;

  static AppThemeFlavor fromName(String? name) =>
      AppThemeFlavor.values.firstWhere(
        (f) => f.name == name,
        orElse: () => AppThemeFlavor.harvest,
      );
}

abstract final class AppColors {
  // Appzeto exact colors
  static const appzetoYellow = Color(0xFFFFD400);
  static const appzetoGreen = Color(0xFF16A34A);
  static const appzetoDarkGreen = Color(0xFF16A34A);
  static const orangeBadge = Color(0xFFFF6B35);

  // Semantic, flavor-independent tokens.
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE4F5EC);
  static const warning = Color(0xFFB8761B);
  static const warningSoft = Color(0xFFFDF1DC);
  static const danger = Color(0xFFD7263D);
  static const dangerSoft = Color(0xFFFDE8EB);
  static const info = Color(0xFF2563EB);

  static const veg = Color(0xFF16A34A);
  static const nonVeg = Color(0xFFB3261E);

  // Light surfaces
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF4F7F1);
  static const lightBorder = Color(0xFFE6EBE2);
  static const lightTextPrimary = Color(0xFF16211A);
  static const lightTextSecondary = Color(0xFF6B7A70);

  // Dark surfaces — hand-picked, not an inversion. Cards sit *above* the
  // background by lightness so elevation stays legible without heavy shadows.
  static const darkBackground = Color(0xFF0B0F0C);
  static const darkSurface = Color(0xFF141A16);
  static const darkSurfaceAlt = Color(0xFF1D2620);
  static const darkBorder = Color(0xFF2A342D);
  static const darkTextPrimary = Color(0xFFF1F5F1);
  static const darkTextSecondary = Color(0xFF9EAFA3);

  static const discountGradient = [Color(0xFF1E88E5), Color(0xFF1565C0)];

  // Mart hero/promo wash — the pale green plate behind banners and offers.
  static const harvestFaint = Color(0xFFF6FAF0);
  static const harvestFaintDark = Color(0xFF112016);
}

/// Tokens the Material [ColorScheme] has no slot for.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.accent,
    required this.brandSurface,
    required this.brandSurfaceSoft,
    required this.onBrandSurface,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.border,
    required this.surfaceAlt,
    required this.textSecondary,
    required this.cardShadow,
    required this.sheetShadow,
    required this.floatingShadow,
  });

  final Color accent;

  /// The saturated brand plate: app header, bottom-nav highlight, badges.
  final Color brandSurface;

  /// The tinted plate used behind hero and promo cards.
  final Color brandSurfaceSoft;

  /// Text/icon colour that is legible on [brandSurface].
  final Color onBrandSurface;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color border;
  final Color surfaceAlt;
  final Color textSecondary;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> sheetShadow;
  final List<BoxShadow> floatingShadow;

  factory AppSemanticColors.light(AppThemeFlavor flavor) => AppSemanticColors(
        accent: flavor.accent,
        brandSurface: flavor.plate,
        brandSurfaceSoft: flavor.plateSoft,
        onBrandSurface: flavor.onPlate,
        success: AppColors.success,
        successSoft: AppColors.successSoft,
        warning: AppColors.warning,
        warningSoft: AppColors.warningSoft,
        danger: AppColors.danger,
        dangerSoft: AppColors.dangerSoft,
        border: AppColors.lightBorder,
        surfaceAlt: AppColors.lightSurfaceAlt,
        textSecondary: AppColors.lightTextSecondary,
        cardShadow: const [
          BoxShadow(color: Color(0x0F101613), blurRadius: 16, offset: Offset(0, 4)),
        ],
        sheetShadow: const [
          BoxShadow(color: Color(0x1A101613), blurRadius: 32, offset: Offset(0, -8)),
        ],
        floatingShadow: [
          BoxShadow(
            color: flavor.seed.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  factory AppSemanticColors.dark(AppThemeFlavor flavor) => AppSemanticColors(
        accent: flavor.accent,
        brandSurface: flavor.plateDark,
        brandSurfaceSoft: flavor.plateSoftDark,
        onBrandSurface: AppColors.darkTextPrimary,
        success: const Color(0xFF3DD68C),
        successSoft: const Color(0xFF13301F),
        warning: const Color(0xFFF2B950),
        warningSoft: const Color(0xFF33260D),
        danger: const Color(0xFFFF6B7A),
        dangerSoft: const Color(0xFF3A1319),
        border: AppColors.darkBorder,
        surfaceAlt: AppColors.darkSurfaceAlt,
        textSecondary: AppColors.darkTextSecondary,
        cardShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
        sheetShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 36, offset: Offset(0, -10)),
        ],
        floatingShadow: [
          BoxShadow(
            color: flavor.seed.withValues(alpha: 0.42),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      );

  @override
  AppSemanticColors copyWith({
    Color? accent,
    Color? brandSurface,
    Color? brandSurfaceSoft,
    Color? onBrandSurface,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? border,
    Color? surfaceAlt,
    Color? textSecondary,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? sheetShadow,
    List<BoxShadow>? floatingShadow,
  }) {
    return AppSemanticColors(
      accent: accent ?? this.accent,
      brandSurface: brandSurface ?? this.brandSurface,
      brandSurfaceSoft: brandSurfaceSoft ?? this.brandSurfaceSoft,
      onBrandSurface: onBrandSurface ?? this.onBrandSurface,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      border: border ?? this.border,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textSecondary: textSecondary ?? this.textSecondary,
      cardShadow: cardShadow ?? this.cardShadow,
      sheetShadow: sheetShadow ?? this.sheetShadow,
      floatingShadow: floatingShadow ?? this.floatingShadow,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      accent: Color.lerp(accent, other.accent, t)!,
      brandSurface: Color.lerp(brandSurface, other.brandSurface, t)!,
      brandSurfaceSoft:
          Color.lerp(brandSurfaceSoft, other.brandSurfaceSoft, t)!,
      onBrandSurface: Color.lerp(onBrandSurface, other.onBrandSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      sheetShadow: t < 0.5 ? sheetShadow : other.sheetShadow,
      floatingShadow: t < 0.5 ? floatingShadow : other.floatingShadow,
    );
  }
}
