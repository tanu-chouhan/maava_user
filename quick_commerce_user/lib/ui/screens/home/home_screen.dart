import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/model/banner.dart';
import '../../../domain/model/coupon.dart';
import '../../../domain/model/product.dart';
import '../../../navigation/route_paths.dart';
import '../../common/smart_scan.dart';
import '../../common/widgets/inputs/search_bar_widget.dart';
import '../../common/widgets/misc/section_header.dart';
import '../../common/widgets/misc/sound_refresh_indicator.dart';
import '../../common/widgets/states/error_state_widget.dart';
import '../../common/widgets/states/offline_banner.dart';
import '../product/product_listing/product_listing_args.dart';
import 'home_provider.dart';
import 'home_state.dart';
import 'widgets/active_order_card.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/delivery_header.dart';
import 'widgets/feature_highlights_row.dart';
import 'widgets/offer_coupons_row.dart';
import 'widgets/product_row.dart';
import 'widgets/shop_by_brand_row.dart';
import 'widgets/shop_by_category_row.dart';
import 'widgets/top_sellers_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// The deal rail prefers the flash-sale ranking and falls back to best
  /// sellers, so the slot is filled by whichever the catalog actually supports
  /// rather than by a placeholder.
  static const _dealSectionIds = ['flash', 'best-sellers'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: context.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: _buildBody(context, state)),
                ],
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: ActiveOrderFloatingCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.failure != null &&
        state.sections.isEmpty &&
        state.categories.isEmpty) {
      return ErrorStateWidget(
        failure: state.failure!,
        onRetry: () => ref.read(homeProvider.notifier).load(refresh: true),
      );
    }

    final dealSectionId = _dealSectionIds.firstWhere(
      (id) => state.productsOf(id).isNotEmpty,
      orElse: () => '',
    );
    final deals = dealSectionId.isEmpty ? const <Product>[] : state.productsOf(dealSectionId);

    return SoundRefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).load(refresh: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // 1. Delivery location, notifications, account.
          const SliverToBoxAdapter(child: DeliveryHeader()),

          // 2. Search + the delivery-promise pill, pinned so search stays
          //    reachable however far the catalog scrolls.
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              background: context.colors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        readOnly: true,
                        categories:
                            state.categories.map((c) => c.name).toList(),
                        onTap: () => context.push(RoutePaths.search),
                        onScanTap: () => SmartScan.run(context, ref),
                        onMicTap: () =>
                            context.push('${RoutePaths.search}?voice=1'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const _DeliveryPromiseBadge(),
                  ],
                ),
              ),
            ),
          ),

          // 3. Hero banners, straight from the published carousel.
          SliverToBoxAdapter(
            child: BannerCarousel(
              banners: state.banners,
              isLoading: state.isLoadingBanners,
              discountPercent: _headlineDiscount(state),
              onTap: (banner) => _openBanner(context, banner),
            ),
          ),

          // 4. Service promises.
          const SliverToBoxAdapter(child: FeatureHighlightsRow()),

          // 5. Shop by category.
          SliverToBoxAdapter(
            child: ShopByCategoryRow(
              categories: state.categories,
              isLoading: state.isLoadingCategories,
              onSeeAll: () => context.go(RoutePaths.categories),
              onCategoryTap: (catId) =>
                  context.push(RoutePaths.subCategoryOf(catId)),
            ),
          ),

          // 6. Live offers as the promo block.
          SliverToBoxAdapter(
            child: OfferCouponsRow(
              coupons: state.coupons,
              isLoading: state.isLoadingCoupons,
              onOfferTap: (_) => context.push(RoutePaths.coupons),
            ),
          ),

          // 7. Deal of the day.
          if (deals.isNotEmpty)
            SliverToBoxAdapter(
              child: _ProductSection(
                title: 'DEAL OF THE DAY',
                seeAllLabel: 'View all deals',
                heroTag: 'home_$dealSectionId',
                products: deals,
                showRanks: dealSectionId == 'best-sellers',
                onSeeAll: () => context.push(
                  RoutePaths.productListing,
                  extra: const ProductListingArgs(title: 'Deals'),
                ),
              ),
            ),

          // 8. Everything else the catalog grouped, in its own order.
          ...state.rows.map(
            (section) => SliverToBoxAdapter(
              child: _ProductSection(
                title: section.title,
                subtitle: section.subtitle,
                heroTag: 'home_${section.id}',
                products: section.products,
                onSeeAll: () => context.push(
                  RoutePaths.productListing,
                  extra: ProductListingArgs(
                    title: section.title,
                    categoryId: section.categoryId,
                  ),
                ),
              ),
            ),
          ),

          // 9. Stores and brands derived from the same catalog.
          SliverToBoxAdapter(
            child: TopSellersRow(
              sellers: state.sellers,
              isLoading: state.isLoadingSections,
              onSeeAll: () => context.push(
                RoutePaths.productListing,
                extra: const ProductListingArgs(title: 'Top Sellers'),
              ),
              onSellerTap: (seller) => context.push(
                RoutePaths.productListing,
                extra: ProductListingArgs(
                  title: seller.name,
                  sellerId: seller.id,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ShopByBrandRow(
              brands: state.brands,
              isLoading: state.isLoadingSections,
              onSeeAll: () => context.push(
                RoutePaths.productListing,
                extra: const ProductListingArgs(title: 'Shop by Brand'),
              ),
              onBrandTap: (brand) => context.push(
                RoutePaths.productListing,
                extra: ProductListingArgs(
                  title: brand.name,
                  brandName: brand.name,
                ),
              ),
            ),
          ),

          // 10. Why shop here.
          const SliverToBoxAdapter(child: ServiceBenefitsPanel()),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl * 2),
          ),
        ],
      ),
    );
  }

  /// The largest percentage a live coupon takes off, for the hero's corner
  /// disc. Flat-rupee coupons have no percentage to quote, so they are skipped
  /// rather than converted into a made-up one.
  int? _headlineDiscount(HomeState state) {
    final percents = state.coupons
        .where((c) => c.discountType == DiscountType.percentage)
        .map((c) => c.discountValue.round())
        .where((p) => p > 0);
    return percents.isEmpty ? null : percents.reduce((a, b) => a > b ? a : b);
  }

  void _openBanner(BuildContext context, PromoBanner banner) {
    switch (banner.target) {
      case BannerTarget.offers:
        context.push(RoutePaths.coupons);
        break;
      case BannerTarget.category:
        if (banner.targetId.isNotEmpty) {
          context.push(RoutePaths.subCategoryOf(banner.targetId));
        } else {
          context.go(RoutePaths.categories);
        }
        break;
      case BannerTarget.restaurant:
        context.push(
          RoutePaths.productListing,
          extra: ProductListingArgs(
            title: banner.title,
            sellerId: banner.targetId,
          ),
        );
        break;
      case BannerTarget.products:
      case BannerTarget.none:
        context.push(
          RoutePaths.productListing,
          extra: ProductListingArgs(
            title: banner.title.isEmpty ? 'Featured Products' : banner.title,
          ),
        );
        break;
    }
  }
}

/// Header + horizontal product rail, the shape every catalog section takes.
class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.heroTag,
    required this.products,
    required this.onSeeAll,
    this.subtitle = '',
    this.seeAllLabel,
    this.showRanks = false,
  });

  final String title;
  final String subtitle;
  final String heroTag;
  final List<Product> products;
  final VoidCallback onSeeAll;
  final String? seeAllLabel;
  final bool showRanks;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            title: title,
            subtitle: subtitle.isEmpty ? null : subtitle,
            onSeeAll: onSeeAll,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
          ),
          ProductRow(
            products: products,
            heroTag: heroTag,
            showRanks: showRanks,
            onProductTap: (product) => context.push(
              RoutePaths.productDetailsOf(product.id),
              extra: product,
            ),
          ),
        ],
      ),
    );
  }
}

/// The delivery promise beside the search field.
class _DeliveryPromiseBadge extends StatelessWidget {
  const _DeliveryPromiseBadge();

  @override
  Widget build(BuildContext context) {
    final onPlate = context.colors.onPrimary;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: onPlate, size: 19),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '10 Min',
                    style: context.text.labelMedium!.copyWith(
                      color: onPlate,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.15,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: onPlate),
                ],
              ),
              Text(
                'Delivery',
                style: context.text.labelMedium!.copyWith(
                  color: onPlate,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps the search row on screen once the location bar has scrolled past.
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchHeaderDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const _extent = 68.0;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: background, child: child);
  }

  @override
  bool shouldRebuild(_SearchHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}
