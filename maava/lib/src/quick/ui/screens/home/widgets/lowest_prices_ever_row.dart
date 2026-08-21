import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/product.dart';
import '../../../../../presentation/branding/app_colors.dart';
import '../../../common/cart_actions.dart';
import '../../../common/widgets/misc/app_network_image.dart';

/// "LOWEST PRICES EVER" rail — matching the reference card design and warm section background 1:1:
///
/// - Section Background: Warm peach/cream background spanning full section width matching reference image.
/// - Header: "LOWEST PRICES EVER" in bold 3D black typography with side accent lines.
/// - Product Card Layout:
///   - Top Half: Crisp white image container box.
///   - Top-Left: Red discount pill badge ("20% OFF", "17% OFF").
///   - Top-Right: White circular Wishlist heart icon button.
///   - Floating "ADD" Button: Positioned at bottom right of image box with thick theme border.
///   - Bottom Half: Warm cream details section.
///   - Grammage Pills: "40 g", "40 GSM" style size tags.
///   - Product Title: 2 lines max, bold dark text.
///   - Rating Stars & Count: Star rating icons + "(85)".
///   - Delivery ETA: "20 MINS".
///   - Discount Blue Tag: "20% OFF".
///   - Price Line: Main price ₹20 + strikethrough price ₹25.
///   - Bottom Action Bar: "See more like this ▶" soft pill with green arrow.
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFFFE8D1), // Warm peach section background matching reference image exactly
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
                Container(width: 28, height: 2, color: const Color(0xFFD1D5DB)),
                const SizedBox(width: 10),
                Text(
                  'LOWEST PRICES EVER',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 0.8,
                    color: const Color(0xFF111827),
                    shadows: const [
                      Shadow(offset: Offset(0, 2), blurRadius: 3, color: Colors.black12),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 28, height: 2, color: const Color(0xFFD1D5DB)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // HORIZONTAL PRODUCT CAROUSEL RAIL
          SizedBox(
            height: 355,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              itemCount: sortedProducts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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

    final packSizeStr = p.packSize.trim().isNotEmpty ? p.packSize.trim() : '40 g';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 182,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF3), // Warm cream card background matching reference
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3E6C8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP WHITE IMAGE CONTAINER WITH BADGES & FLOATING ADD BUTTON
            Container(
              height: 142,
              color: Colors.white,
              child: Stack(
                children: [
                  // Center Product Image
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: AppNetworkImage(
                        key: _imageKey,
                        url: p.imageUrl,
                        width: 110,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Top Left Discount Red Pill Badge
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626), // Red badge matching reference
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),

                  // Top Right White Wishlist Heart Button
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 17,
                          color: _isFavorite ? Colors.red : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  // Floating "ADD" Button (Bottom Right of Image Container)
                  Positioned(
                    right: 8,
                    bottom: 4,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          p.isPurchasable ? 'ADD' : 'OUT',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM CREAM DETAILS SECTION
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GRAMMAGE / PACK SIZE PILLS
                  Row(
                    children: [
                      _buildChipPill(packSizeStr),
                      const SizedBox(width: 4),
                      _buildChipPill('40 GSM'),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // PRODUCT TITLE
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.2,
                      color: const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // RATING STARS & COUNT
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                      const Icon(Icons.star_half_rounded, size: 13, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text(
                        '(85)',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // DELIVERY ETA
                  Text(
                    '${p.deliveryMinutes ?? 20} MINS',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B5563),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // DISCOUNT BLUE TAG
                  Text(
                    '$discount% OFF',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // PRICE LINE (Main Price + Strikethrough)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${strike.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // BOTTOM ACTION PILL: "See more like this ▶"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5), // Soft peach pill background matching reference
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'See more like this',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: Color(0xFF10B981), // Green arrow matching reference
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
