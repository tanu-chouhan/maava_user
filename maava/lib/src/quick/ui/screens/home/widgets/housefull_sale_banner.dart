import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../presentation/branding/app_colors.dart';
import '../../../../domain/model/category.dart';
import '../../../../domain/model/product.dart';

/// Housefull Sale Banner matching the reference layout & structure:
///
/// - Top 3D Text: "HOUSEFULL SALE"
/// - Date Sub-label: "30TH NOV, 2025 - 7TH DEC, 2025"
/// - Left Side Card: "CRAZY DEALS" (Price badges ₹198 → ₹129, category label & product image box)
/// - Right Side Grid (2x2):
///   1. Up to 55% OFF - Self Care & Wellness (Icons: 🧴 💧 🧼 💄)
///   2. Up to 55% OFF - Hot Meals & Drinks (Icons: 🍜 ☕ 🥛 🍞)
///   3. Up to 55% OFF - Kitchen Essentials (Icons: 🌾 🍚 🫘 🫒)
///   4. Up to 75% OFF - Cleaning & Home Needs (Icons: 🧹 🧽 🧼 🧴)
/// - Bottom Wavy / Scalloped Edge transitioning into the white content area.
/// - Dynamic Palette: Built using active theme color ([AppColors.primary]).
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
    final primaryLight = AppColors.primaryLight;

    return ClipPath(
      clipper: const _ScallopedEdgeClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryDeep,
              primary,
              primaryLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: Column(
          children: [
            // TOP SALE TITLE & DECORATIVE SPARKLES
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 24,
                  top: 0,
                  child: Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 26),
                ),
                const Positioned(
                  right: 24,
                  top: 0,
                  child: Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700), size: 26),
                ),
                const Positioned(
                  left: 6,
                  top: 18,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 16),
                ),
                const Positioned(
                  right: 6,
                  top: 18,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 16),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HOUSEFULL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 1.2,
                        color: Colors.white,
                        shadows: const [
                          Shadow(offset: Offset(0, 3), blurRadius: 0, color: Color(0x73000000)),
                          Shadow(offset: Offset(0, 5), blurRadius: 4, color: Color(0x33000000)),
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
                        letterSpacing: 2.0,
                        color: Colors.white,
                        shadows: const [
                          Shadow(offset: Offset(0, 2.5), blurRadius: 0, color: Color(0x73000000)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '30TH NOV, 2025 - 7TH DEC, 2025',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // MAIN CONTENT GRID: CRAZY DEALS CARD (LEFT) + 2x2 CATEGORIES GRID (RIGHT)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: CRAZY DEALS CARD
                  Expanded(
                    flex: 4,
                    child: _buildCrazyDealsCard(context),
                  ),

                  const SizedBox(width: 10),

                  // RIGHT: 2x2 CATEGORY OFFER CARDS GRID
                  Expanded(
                    flex: 7,
                    child: _buildCategoryGrid(context),
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

  Widget _buildCrazyDealsCard(BuildContext context) {
    final strikePrice = dealProduct?.strikePrice ?? 198;
    final dealPrice = dealProduct?.price ?? 129;
    final titleLabel = dealProduct?.name ?? 'Biscuit';
    final imageUrl = dealProduct?.imageUrl ?? '';

    return GestureDetector(
      onTap: onCrazyDealsTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
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
                      Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x66000000)),
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
                      Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x66000000)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Original Price Badge (strikethrough)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
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

                // Deal Price Badge (accent highlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
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
                    fontSize: 11.5,
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.cookie_outlined,
                        color: Color(0xFF6B7280),
                        size: 36,
                      ),
                    )
                  : const Icon(
                      Icons.cookie_outlined,
                      color: Color(0xFF6B7280),
                      size: 36,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
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
        title: 'Cleaning & Home\nNeeds',
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
              Expanded(child: _buildCategoryCard(context, cards[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(context, cards[1])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildCategoryCard(context, cards[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(context, cards[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, _CategoryCardData data) {
    final primary = AppColors.primary;

    return GestureDetector(
      onTap: () => onCategoryCardTap?.call(data.categoryId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Discount Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary,
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
                color: const Color(0xFF111111),
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
