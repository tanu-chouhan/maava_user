import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/category.dart';

/// Bestsellers Category Collage Section matching the reference design 1:1:
///
/// - Title: "Bestsellers" in bold headline typography.
/// - 2-row x 3-column Grid (6 category collage cards).
/// - Each Card features:
///   - 2x2 thumbnail image grid inside a light blue/mint container.
///   - "+172 more" count pill badge.
///   - Bold category title label ("Vegetables & Fruits", "Oil, Ghee & Masala", etc.).
class BestsellersRow extends StatelessWidget {
  const BestsellersRow({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.onSeeAll,
  });

  final List<Category> categories;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    // Preset Bestseller Categories matching the reference screenshot exactly
    final List<_BestsellerCardData> defaultItems = [
      const _BestsellerCardData(
        id: 'veg_fruits',
        title: 'Vegetables &\nFruits',
        moreCount: '+172 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=150',
          'https://images.unsplash.com/photo-1518843875459-f738682238a6?w=150',
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=150',
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=150',
        ],
      ),
      const _BestsellerCardData(
        id: 'oil_ghee',
        title: 'Oil, Ghee &\nMasala',
        moreCount: '+239 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=150',
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=150',
          'https://images.unsplash.com/photo-1599909631366-4e55e69e2c60?w=150',
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=150',
        ],
      ),
      const _BestsellerCardData(
        id: 'dairy_bread',
        title: 'Dairy, Bread &\nEggs',
        moreCount: '+32 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=150',
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=150',
          'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=150',
          'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=150',
        ],
      ),
      const _BestsellerCardData(
        id: 'chips_namkeen',
        title: 'Chips &\nNamkeen',
        moreCount: '+382 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=150',
          'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=150',
          'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=150',
          'https://images.unsplash.com/photo-1528751014936-863e6e7a319c?w=150',
        ],
      ),
      const _BestsellerCardData(
        id: 'bakery_biscuits',
        title: 'Bakery &\nBiscuits',
        moreCount: '+214 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=150',
          'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=150',
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=150',
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=150',
        ],
      ),
      const _BestsellerCardData(
        id: 'atta_rice',
        title: 'Atta, Rice &\nDal',
        moreCount: '+109 more',
        imageUrls: [
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=150',
          'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?w=150',
          'https://images.unsplash.com/photo-1514944288352-fffac99f0bdf?w=150',
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=150',
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION TITLE: "Bestsellers"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text(
              'Bestsellers',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.3,
                color: const Color(0xFF111827),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2-ROW x 3-COLUMN GRID
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBestsellerCard(context, defaultItems[0])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBestsellerCard(context, defaultItems[1])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBestsellerCard(context, defaultItems[2])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBestsellerCard(context, defaultItems[3])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBestsellerCard(context, defaultItems[4])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBestsellerCard(context, defaultItems[5])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestsellerCard(BuildContext context, _BestsellerCardData item) {
    return GestureDetector(
      onTap: () {
        final match = categories.firstWhere(
          (c) => c.name.toLowerCase().contains(item.id.toLowerCase()) || c.id == item.id,
          orElse: () => categories.isNotEmpty ? categories.first : Category(id: item.id, name: item.title),
        );
        onCategoryTap(match.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          children: [
            // 2x2 THUMBNAIL GRID CONTAINER
            Container(
              height: 82,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildThumbImage(item.imageUrls[0])),
                        const SizedBox(width: 3),
                        Expanded(child: _buildThumbImage(item.imageUrls[1])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildThumbImage(item.imageUrls[2])),
                        const SizedBox(width: 3),
                        Expanded(child: _buildThumbImage(item.imageUrls[3])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // COUNT PILL BADGE ("+172 more")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.moreCount,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // CATEGORY TITLE LABEL
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbImage(String url) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.fastfood_outlined,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _BestsellerCardData {
  const _BestsellerCardData({
    required this.id,
    required this.title,
    required this.moreCount,
    required this.imageUrls,
  });

  final String id;
  final String title;
  final String moreCount;
  final List<String> imageUrls;
}
