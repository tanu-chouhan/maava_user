import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/category.dart';
import '../../../common/widgets/cards/category_card.dart';

/// Sequentially renders ALL available backend product categories grouped by section
/// in 4-column grids matching the reference screenshot 1:1.
class AllCategorySectionsFeed extends StatelessWidget {
  const AllCategorySectionsFeed({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final ValueChanged<String> onCategoryTap;

  Map<String, List<Category>> _groupCategories(List<Category> all) {
    final Map<String, List<Category>> groups = {
      'Grocery & Kitchen': [],
      'Snacks & Drinks': [],
      'Beauty & Personal Care': [],
      'Household Essentials': [],
    };

    for (final cat in all) {
      final name = cat.name.toLowerCase();
      if (name.contains('veg') ||
          name.contains('fruit') ||
          name.contains('atta') ||
          name.contains('rice') ||
          name.contains('dal') ||
          name.contains('oil') ||
          name.contains('ghee') ||
          name.contains('masala') ||
          name.contains('dairy') ||
          name.contains('bread') ||
          name.contains('egg') ||
          name.contains('bakery') ||
          name.contains('biscuit') ||
          name.contains('dry fruit') ||
          name.contains('cereal') ||
          name.contains('chicken') ||
          name.contains('meat') ||
          name.contains('fish') ||
          name.contains('kitchen') ||
          name.contains('groc')) {
        groups['Grocery & Kitchen']!.add(cat);
      } else if (name.contains('chip') ||
          name.contains('namkeen') ||
          name.contains('sweet') ||
          name.contains('choc') ||
          name.contains('drink') ||
          name.contains('juice') ||
          name.contains('tea') ||
          name.contains('coffee') ||
          name.contains('milk') ||
          name.contains('instant') ||
          name.contains('sauce') ||
          name.contains('spread') ||
          name.contains('paan') ||
          name.contains('ice cream') ||
          name.contains('snack') ||
          name.contains('beverage')) {
        groups['Snacks & Drinks']!.add(cat);
      } else if (name.contains('beauty') ||
          name.contains('bath') ||
          name.contains('body') ||
          name.contains('hair') ||
          name.contains('skin') ||
          name.contains('baby') ||
          name.contains('cosmetic') ||
          name.contains('personal')) {
        groups['Beauty & Personal Care']!.add(cat);
      } else {
        groups['Household Essentials']!.add(cat);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);

    if (groups.isEmpty && all.isNotEmpty) {
      groups['All Categories'] = all;
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final grouped = _groupCategories(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter, 12),
            child: Text(
              entry.key,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {
                final category = entry.value[index];
                return CategoryCard(
                  category: category,
                  size: 74,
                  onTap: () => onCategoryTap(category.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
