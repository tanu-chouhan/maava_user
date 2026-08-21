import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/product.dart';
import '../../../../../presentation/branding/app_colors.dart';
import '../../../common/cart_actions.dart';
import '../../../common/widgets/misc/app_network_image.dart';

/// "LOWEST PRICES EVER" rail — matching the reference card design exactly:
///
/// - Title: "LOWEST PRICES EVER" with 3D typography flanked by accent lines.
/// - Card Container: Cream tint background with rounded corners and subtle border.
/// - Top Left: Red discount pill badge ("20% OFF", "17% OFF").
/// - Top Right: White circular Wishlist Heart button.
/// - Image Center: Product image.
/// - Floating "ADD" button: Bordered white pill at bottom right of image area.
/// - Grammage Pills: "40 g", "40 GSM" style size tags.
/// - Rating Stars & Count: Star rating icons + "(85)".
/// - Delivery ETA: "20 MINS".
/// - Discount Blue Tag: "20% OFF".
/// - Price Line: Main price ₹20 + strikethrough price ₹25.
/// - Bottom Action Bar: "See more like this ▶" pill.
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE HEADER: "— LOWEST PRICES EVER —"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 24, height: 2, color: const Color(0xFFD1D5DB)),
                const SizedBox(width: 10),
                Text(
                  'LOWEST PRICES EVER',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.8,
                    color: const Color(0xFF111827),
                    shadows: const [
                      Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black12),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 24, height: 2, color: const Color(0xFFD1D5DB)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // HORIZONTAL PRODUCT CAROUSEL RAIL
          SizedBox(
            height: 350,
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
        width: 176,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5), // Warm cream background matching reference
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3E8CE), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP IMAGE CONTAINER WITH BADGES & FLOATING ADD BUTTON
            SizedBox(
              height: 135,
              child: Stack(
                children: [
                  // Center Product Image
                  Center(
                    child: AppNetworkImage(
                      key: _imageKey,
                      url: p.imageUrl,
                      width: 110,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Top Left Discount Badge Tag
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626), // Vibrant red discount pill
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

                  // Top Right Favorite Heart Button
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: _isFavorite ? Colors.red : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),

                  // Floating "ADD" Button (Bottom Right)
                  Positioned(
                    right: 0,
                    bottom: 0,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          p.isPurchasable ? 'ADD' : 'OUT',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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
                fontSize: 12,
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

            const SizedBox(height: 4),

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

            const Spacer(),

            // BOTTOM ACTION PILL: "See more like this ▶"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'See more like this',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 13,
                    color: Color(0xFF059669),
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
