import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../presentation/branding/app_colors.dart';
import '../../../../domain/model/category.dart';
import '../../../../domain/model/product.dart';
import 'bouncing_heading.dart';

/// Housefull Sale Banner matching the reference layout & structure:
///
/// - Deep Midnight Contrast Background for high 3D pop against header.
/// - Top 3D Text: "HOUSEFULL SALE" with Gold Sparkle Icons ⚡
/// - Date Sub-label Pill: "30TH NOV, 2025 - 7TH DEC, 2025"
/// - Left Side CRAZY DEALS Card: High-contrast gradient card with Gold border,
///   dark strikethrough price pill, red deal price pill & white image box.
/// - Right Side Grid (2x2): Pure white rounded cards with vibrant discount badges.
/// - Bottom Wavy / Scalloped Edge transitioning into the white content area.
class HousefullSaleBanner extends StatelessWidget {
  const HousefullSaleBanner({
    super.key,
    this.dealProduct,
    this.categories = const [],
    this.onCrazyDealsTap,
    this.onCategoryCardTap,
  });

  final Product? dealProduct;
  final List<Category> categories;
  final VoidCallback? onCrazyDealsTap;
  final ValueChanged<String>? onCategoryCardTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final primaryDeep = AppColors.primaryDeep;

    // High-contrast deep midnight brand gradient for maximum 3D separation from header
    final HSLColor hsl = HSLColor.fromColor(primary);
    final Color deepMidnight = hsl
        .withLightness((hsl.lightness * 0.28).clamp(0.06, 0.22))
        .withSaturation((hsl.saturation * 0.95).clamp(0.5, 0.95))
        .toColor();
    final Color richDeepBrand = hsl
        .withLightness((hsl.lightness * 0.42).clamp(0.15, 0.35))
        .toColor();
    final Color midBrand = hsl
        .withLightness((hsl.lightness * 0.58).clamp(0.32, 0.52))
        .toColor();

    return ClipPath(
      clipper: const _ScallopedEdgeClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              deepMidnight,
              richDeepBrand,
              midBrand,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
        child: Column(
          children: [
            // TOP SALE TITLE & DECORATIVE SPARKLES
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 20,
                  top: -2,
                  child: Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 28),
                ),
                const Positioned(
                  right: 20,
                  top: -2,
                  child: Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 28),
                ),
                const Positioned(
                  left: 4,
                  top: 18,
                  child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE68A), size: 16),
                ),
                const Positioned(
                  right: 4,
                  top: 18,
                  child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE68A), size: 16),
                ),
                BouncingHeading(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HOUSEFULL',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: 1.5,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(0, 3), blurRadius: 0, color: Color(0x99000000)),
                            Shadow(offset: Offset(0, 6), blurRadius: 6, color: Color(0x4D000000)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SALE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: 2.2,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(0, 2.5), blurRadius: 0, color: Color(0x99000000)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date range pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '30TH NOV, 2025 - 7TH DEC, 2025',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFDE68A),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // MAIN CONTENT GRID: CRAZY DEALS CARD (LEFT) + 2x2 CATEGORIES GRID (RIGHT)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: CRAZY DEALS CARD
                  Expanded(
                    flex: 4,
                    child: _buildCrazyDealsCard(context, primary, primaryDeep),
                  ),

                  const SizedBox(width: 10),

                  // RIGHT: 2x2 CATEGORY OFFER CARDS GRID
                  Expanded(
                    flex: 7,
                    child: _buildCategoryGrid(context, primary, primaryDeep),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCrazyDealsCard(BuildContext context, Color primary, Color primaryDeep) {
    final strikePrice = dealProduct?.strikePrice ?? 200;
    final dealPrice = dealProduct?.price ?? 150;
    final titleLabel = dealProduct?.name ?? 'cherry';
    final imageUrl = dealProduct?.imageUrl ?? '';

    return GestureDetector(
      onTap: onCrazyDealsTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary,
              primaryDeep,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFBBF24), // Vibrant Gold border matching reference
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  'CRAZY',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x8C000000)),
                    ],
                  ),
                ),
                Text(
                  'DEALS',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x8C000000)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Original Price Badge (strikethrough)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${strikePrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Deal Price Badge (Vibrant Accent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), // Vibrant Red badge for max pop
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '₹${dealPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Product title label
                Text(
                  titleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Product Image White Box Container
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.fastfood_rounded,
                        color: Color(0xFF7C3AED),
                        size: 34,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      color: Color(0xFF7C3AED),
                      size: 34,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, Color primary, Color primaryDeep) {
    final List<_CategoryCardData> cards = [
      const _CategoryCardData(
        title: 'Self Care &\nWellness',
        badgeText: 'Up to 55% OFF',
        emojis: '🧴 💧 🧼 💄',
        categoryId: 'wellness',
      ),
      const _CategoryCardData(
        title: 'Hot Meals &\nDrinks',
        badgeText: 'Up to 55% OFF',
        emojis: '🍜 ☕ 🥛 🍞',
        categoryId: 'meals',
      ),
      const _CategoryCardData(
        title: 'Kitchen\nEssentials',
        badgeText: 'Up to 55% OFF',
        emojis: '🌾 🍚 🫘 🫒',
        categoryId: 'kitchen',
      ),
      const _CategoryCardData(
        title: 'Cleaning &\nHome',
        badgeText: 'Up to 75% OFF',
        emojis: '🧹 🧽 🧼 🧴',
        categoryId: 'cleaning',
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCategoryCard(context, cards[0], primary, primaryDeep)),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(context, cards[1], primary, primaryDeep)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCategoryCard(context, cards[2], primary, primaryDeep)),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(context, cards[3], primary, primaryDeep)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _CategoryCardData data,
    Color primary,
    Color primaryDeep,
  ) {
    return GestureDetector(
      onTap: () => onCategoryCardTap?.call(data.categoryId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Discount Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary,
                    primaryDeep,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                data.badgeText,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Card Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
            ),

            const SizedBox(height: 4),

            // Category Emojis / Graphics Row
            Text(
              data.emojis,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCardData {
  const _CategoryCardData({
    required this.title,
    required this.badgeText,
    required this.emojis,
    required this.categoryId,
  });

  final String title;
  final String badgeText;
  final String emojis;
  final String categoryId;
}

class _ScallopedEdgeClipper extends CustomClipper<Path> {
  const _ScallopedEdgeClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 12);

    const scallopWidth = 18.0;
    final count = (size.width / scallopWidth).ceil();

    for (int i = 0; i < count; i++) {
      final x = i * scallopWidth;
      path.quadraticBezierTo(
        x + scallopWidth / 2,
        size.height,
        x + scallopWidth,
        size.height - 12,
      );
    }

    path.lineTo(size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
