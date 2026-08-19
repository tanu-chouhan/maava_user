import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/model/category.dart';
import '../../../common/widgets/loaders/shimmer_box.dart';
import '../../../common/widgets/misc/app_network_image.dart';
import '../../../common/widgets/misc/section_header.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_theme.dart';

/// "Shop by Category" tiles, backed by the real top-level category list.
class ShopByCategoryRow extends StatelessWidget {
  const ShopByCategoryRow({
    super.key,
    this.categories = const [],
    this.isLoading = false,
    this.onCategoryTap,
    this.onSeeAll,
  });

  final List<Category> categories;
  final bool isLoading;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'SHOP BY CATEGORY',
          onSeeAll: onSeeAll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
        ),
        SizedBox(
          height: 128,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
          categories.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: 4,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, _) => const Column(
                    children: [
                      ShimmerBox(width: 78, height: 78, radius: AppRadii.rLg),
                      SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 70, height: 10),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    return GestureDetector(
                      onTap: () => onCategoryTap?.call(item.id),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          children: [
                            Container(
                              height: 78,
                              width: 78,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: AppRadii.rLg,
                                border: Border.all(
                                  color: context.semantic.border,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AppNetworkImage(
                                url: item.imageUrl,
                                fit: BoxFit.contain,
                                fallbackIcon: Icons.category_rounded,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colors.onSurface,
                                fontSize: 10,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (categories.isNotEmpty)
                IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2, bottom: 30),
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.semantic.border),
                      boxShadow: context.semantic.cardShadow,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
