import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/product.dart';
import '../../../../../presentation/branding/app_colors.dart';
import '../../../common/cart_actions.dart';
import '../../../common/widgets/misc/app_network_image.dart';

/// "LOWEST PRICES EVER" section rail:
///
/// - Section Background: Uses active default app theme color tint ([AppColors.primaryTint]) - no hardcoded orange!
/// - Compact Card Dimensions: Reduced card width & height for a sleeker, space-efficient product grid.
/// - Product Card Layout:
///   - Top Half: Crisp white image container box.
///   - Top-Left: Red discount pill badge ("20% OFF", "17% OFF").
///   - Top-Right: White circular Wishlist heart icon button.
///   - Floating "ADD" Button: Compact bordered button in active theme color.
///   - Bottom Half: Compact details section styled with active theme accents.
///   - Grammage Pills: "40 g", "40 GSM" style size tags.
///   - Product Title: 2 lines max, bold dark text.
///   - Rating Stars & Count: Star rating icons + "(85)".
///   - Delivery ETA: "20 MINS".
///   - Discount Tag: "20% OFF" in active theme color.
///   - Price Line: Main price ₹20 + strikethrough price ₹25.
///   - Bottom Action Bar: "See more like this ▶" soft pill with active theme arrow.
/// - Product Sorting: Lowest-priced products displayed first!
class LowestPricesEverRow extends ConsumerWidget {
  const LowestPricesEverRow({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final void Function(Product) onProductTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) return const SizedBox.shrink();

    // Sort products by price ascending (lowest price first)
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) => a.price.compareTo(b.price));

    final primaryTint = AppColors.primaryTint;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: primaryTint, // Dynamic default app theme background tint
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE HEADER: "— LOWEST PRICES EVER —"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 24, height: 2, color: const Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Text(
                  'LOWEST PRICES EVER',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.6,
                    color: const Color(0xFF111827),
                    shadows: const [
                      Shadow(offset: Offset(0, 1.5), blurRadius: 2, color: Colors.black12),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 24, height: 2, color: const Color(0xFF9CA3AF)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // HORIZONTAL PRODUCT CAROUSEL RAIL (COMPACT HEIGHT 268)
          SizedBox(
            height: 268,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              itemCount: sortedProducts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _LowestPriceCard(
                product: sortedProducts[i],
                onTap: () => onProductTap(sortedProducts[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowestPriceCard extends ConsumerStatefulWidget {
  const _LowestPriceCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  ConsumerState<_LowestPriceCard> createState() => _LowestPriceCardState();
}

class _LowestPriceCardState extends ConsumerState<_LowestPriceCard> {
  final _imageKey = GlobalKey();
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final strike = p.strikePrice ?? (p.price * 1.25);
    final discount = p.discountPercent > 0 ? p.discountPercent : 20;
    final primaryColor = AppColors.primary;
    final primaryTintStrong = AppColors.primaryTintStrong;

    final packSizeStr = p.packSize.trim().isNotEmpty ? p.packSize.trim() : '40 g';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 140, // Reduced compact width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryTintStrong, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP WHITE IMAGE CONTAINER WITH BADGES & FLOATING ADD BUTTON
            Container(
              height: 100,
              color: Colors.white,
              child: Stack(
                children: [
                  // Center Product Image
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: AppNetworkImage(
                        key: _imageKey,
                        url: p.imageUrl,
                        width: 76,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Top Left Discount Red Pill Badge
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ),

                  // Top Right White Wishlist Heart Button
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 13,
                          color: _isFavorite ? Colors.red : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  // Floating "ADD" Button (Bottom Right of Image Container)
                  Positioned(
                    right: 6,
                    bottom: 3,
                    child: GestureDetector(
                      onTap: p.isPurchasable
                          ? () => CartActions.add(
                                context,
                                ref,
                                product: p,
                                sourceKey: _imageKey,
                              )
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          p.isPurchasable ? 'ADD' : 'OUT',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM DETAILS SECTION
            Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GRAMMAGE / PACK SIZE PILLS
                  Row(
                    children: [
                      _buildChipPill(packSizeStr),
                      const SizedBox(width: 3),
                      _buildChipPill('40 GSM'),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // PRODUCT TITLE
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      height: 1.15,
                      color: const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // RATING STARS & COUNT
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_half_rounded, size: 10.5, color: Color(0xFFFFB800)),
                      const SizedBox(width: 2),
                      Text(
                        '(85)',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // DELIVERY ETA
                  Text(
                    '${p.deliveryMinutes ?? 20} MINS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B5563),
                    ),
                  ),

                  const SizedBox(height: 1),

                  // DISCOUNT TAG
                  Text(
                    '$discount% OFF',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // PRICE LINE (Main Price + Strikethrough)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '₹${strike.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // BOTTOM ACTION PILL: "See more like this ▶"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: primaryTintStrong,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'See more like this',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeepText,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 11,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
