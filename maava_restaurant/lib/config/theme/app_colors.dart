import 'package:flutter/material.dart';

/// Centralized colour palette. Every screen should pull brand colours from
/// here rather than hardcoding a hex — that is what keeps the purple identity
/// consistent and makes a future re-brand a one-file change.
///
/// Hierarchy, deliberately *not* "purple everywhere":
///  * [primary] — primary actions and selected states.
///  * [primaryDark] — pressed/darker emphasis.
///  * [primarySurface] / [primarySurfaceSubtle] — tinted containers.
///  * backgrounds stay white/near-white, text stays near-black.
///  * [success] / [warning] / [error] stay semantic — a "delivered" tick or an
///    out-of-stock warning must not read as a brand accent.
class AppColors {
  // ==================== BRAND COLORS ====================
  static const Color primary = Color(0xFF8B5CF6); // Brand purple
  static const Color primaryDark = Color(0xFF6D3FD1); // Pressed / emphasis
  static const Color primaryLight = Color(0xFFA78BFA); // Lighter accent

  /// Tinted container backgrounds (chips, selected rows, banners).
  static const Color primarySurface = Color(0xFFF1ECFF); // Light purple
  static const Color primarySurfaceSubtle = Color(0xFFF8F5FF); // Very light

  /// Hairline borders on tinted containers.
  static const Color primaryBorder = Color(0xFFE3D9FF);

  // ==================== DARK THEME COLORS ====================
  static const Color backgroundDark = Color(0xFF15121F); // Purple-tinted ink
  static const Color surfaceDark = Color(0xFF1F1A2E); // Card background
  static const Color surfaceVariantDark = Color(
    0xFF2A2440,
  ); // Lighter surface for chips/inputs

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA9A3BD);

  // ==================== LIGHT THEME COLORS ====================
  static const Color backgroundLight = Color(0xFFF8F5FF); // Very light purple
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1ECFF);

  static const Color textPrimaryLight = Color(0xFF171717);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  /// Neutral hairline for cards/dividers on white.
  static const Color border = Color(0xFFE5E7EB);

  static const Color white = Color(0xFFFFFFFF);

  // ==================== STATUS & ACCENT COLORS ====================
  // Semantic only — never used as brand accents.
  static const Color success = Color(0xFF16A34A);
  static const Color successSurface = Color(0xFFECFDF3);
  static const Color warning = Color(0xFFB54708);
  static const Color warningSurface = Color(0xFFFFFAEB);
  static const Color rating = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEF3F2);

  /// Sequential ramp for rating distributions (1 star -> 5 stars). Semantic,
  /// not brand: a low rating must read as bad, so this stays red -> green.
  static const List<Color> ratingScale = [
    Color(0xFFDC2626),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFFA3E635),
    Color(0xFF4ADE80),
    Color(0xFF16A34A),
  ];
}
