import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/category.dart';
import '../../../common/widgets/cards/category_card.dart';

/// Takes ALL categories present inside the "Shop by Category" section from the backend
/// and creates a SEPARATE SECTION for each category with a 4-column subcategory grid
/// matching the reference screenshot 1:1.
class AllCategorySectionsFeed extends StatelessWidget {
  const AllCategorySectionsFeed({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final ValueChanged<String> onCategoryTap;

  Map<String, List<Category>> _resolveCategorySections(List<Category> allCategories) {
    final Map<String, List<Category>> categorySections = {};

    // 1. Grocery & Kitchen Subcategories
    final List<Category> grocerySubCats = [
      const Category(id: 'veg_fruits', name: 'Vegetables &\nFruits', imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=150'),
      const Category(id: 'atta_rice', name: 'Atta, Rice &\nDal', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=150'),
      const Category(id: 'oil_ghee', name: 'Oil, Ghee &\nMasala', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=150'),
      const Category(id: 'dairy_bread', name: 'Dairy, Bread &\nEggs', imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=150'),
      const Category(id: 'bakery_biscuits', name: 'Bakery &\nBiscuits', imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=150'),
      const Category(id: 'dry_fruits', name: 'Dry Fruits &\nCereals', imageUrl: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=150'),
      const Category(id: 'chicken_meat', name: 'Chicken, Meat\n& Fish', imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=150'),
      const Category(id: 'kitchenware', name: 'Kitchenware &\nAppliances', imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=150'),
    ];

    // 2. Snacks & Drinks Subcategories
    final List<Category> snacksSubCats = [
      const Category(id: 'chips_namkeen', name: 'Chips &\nNamkeen', imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=150'),
      const Category(id: 'sweets_choc', name: 'Sweets &\nChocolates', imageUrl: 'https://images.unsplash.com/photo-1582293041079-7814c2f12063?w=150'),
      const Category(id: 'drinks_juices', name: 'Drinks &\nJuices', imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=150'),
      const Category(id: 'tea_coffee', name: 'Tea, Coffee &\nMilk Drinks', imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=150'),
      const Category(id: 'instant_food', name: 'Instant Food', imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=150'),
      const Category(id: 'sauces_spreads', name: 'Sauces &\nSpreads', imageUrl: 'https://images.unsplash.com/photo-1472476443507-c7a5948772fc?w=150'),
      const Category(id: 'paan_corner', name: 'Paan Corner', imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=150'),
      const Category(id: 'ice_creams', name: 'Ice Creams &\nMore', imageUrl: 'https://images.unsplash.com/photo-1567206563064-6f60f4078b57?w=150'),
    ];

    // 3. Beauty & Personal Care Subcategories
    final List<Category> beautySubCats = [
      const Category(id: 'skin_care', name: 'Skin Care', imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=150'),
      const Category(id: 'hair_care', name: 'Hair Care', imageUrl: 'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=150'),
      const Category(id: 'bath_body', name: 'Bath & Body', imageUrl: 'https://images.unsplash.com/photo-1608248597263-0057e43a4524?w=150'),
      const Category(id: 'oral_care', name: 'Oral Care', imageUrl: 'https://images.unsplash.com/photo-1559599101-f09722fb4948?w=150'),
    ];

    // 4. Household Essentials Subcategories
    final List<Category> householdSubCats = [
      const Category(id: 'cleaning_home', name: 'Cleaning &\nHome', imageUrl: 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=150'),
      const Category(id: 'detergents', name: 'Detergents &\nFabric Care', imageUrl: 'https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=150'),
      const Category(id: 'disposables', name: 'Paper &\nDisposables', imageUrl: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=150'),
      const Category(id: 'pooja_needs', name: 'Pooja Needs', imageUrl: 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=150'),
    ];

    for (final cat in allCategories) {
      final name = cat.name.trim();
      final lowerName = name.toLowerCase();

      if (lowerName.contains('groc') || lowerName.contains('kitchen')) {
        categorySections[name] = grocerySubCats;
      } else if (lowerName.contains('snack') || lowerName.contains('drink') || lowerName.contains('beverage')) {
        categorySections[name] = snacksSubCats;
      } else if (lowerName.contains('beauty') || lowerName.contains('personal') || lowerName.contains('care')) {
        categorySections[name] = beautySubCats;
      } else if (lowerName.contains('house') || lowerName.contains('clean')) {
        categorySections[name] = householdSubCats;
      } else {
        final subCats = allCategories.where((c) => c.id != cat.id).take(4).toList();
        categorySections[name] = subCats.isNotEmpty ? subCats : [cat];
      }
    }

    return categorySections;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final sections = _resolveCategorySections(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in sections.entries) ...[
          // Category Section Heading
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter, 10),
            child: Text(
              entry.key,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),

          // 4-Column Subcategory Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final subCategory = entry.value[index];
                return CategoryCard(
                  category: subCategory,
                  size: 70,
                  onTap: () => onCategoryTap(subCategory.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
