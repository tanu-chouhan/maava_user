import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/branding/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../navigation/route_paths.dart';
import '../../common/widgets/misc/section_header.dart';
import '../../common/widgets/misc/sound_refresh_indicator.dart';
import '../../common/widgets/states/error_state_widget.dart';
import '../../common/widgets/states/offline_banner.dart';
import '../product/product_listing/product_listing_args.dart';
import 'home_provider.dart';
import '../../../domain/model/product.dart';
import 'home_state.dart';
import 'widgets/deal_of_the_day_row.dart';
import 'widgets/delivery_header.dart';
import 'widgets/feature_highlights_row.dart';
import 'widgets/all_category_sections_feed.dart';
import 'widgets/bestsellers_row.dart';
import 'widgets/featured_this_week_row.dart';
import 'widgets/housefull_sale_banner.dart';
import 'widgets/lowest_prices_ever_row.dart';
import 'widgets/shop_by_category_row.dart';
import 'widgets/value_props_strip.dart';
import 'widgets/active_order_card.dart';
import 'widgets/product_row.dart';
import 'widgets/shop_by_brand_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > 180;
    if (isCollapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = isCollapsed);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final isDarkIcon = HSLColor.fromColor(AppColors.primary).lightness > 0.65;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Match status bar color seamlessly with active theme header
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkIcon ? Brightness.dark : Brightness.light,
        statusBarBrightness: isDarkIcon ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  const OfflineBanner(),
                  Expanded(
                    child: _buildBody(context, state, topPadding),
                  ),
                ],
              ),
            ),

            // Active Order Floating Card above bottom navigation
            const Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: ActiveOrderFloatingCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state, double topPadding) {
    if (state.failure != null &&
        state.sections.isEmpty &&
        state.categories.isEmpty) {
      return ErrorStateWidget(
        failure: state.failure!,
        onRetry: () => ref.read(homeProvider.notifier).load(refresh: true),
      );
    }

    return SoundRefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).load(refresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        // Platform default over-scroll, not iOS bounce.
        //
        // BouncingScrollPhysics drags the whole list down on a pull and springs
        // it back, which read as the page jumping and re-scrolling on every
        // refresh. `AlwaysScrollable` keeps pull-to-refresh working when the
        // content is shorter than the viewport, while over-scroll falls back to
        // the platform's own (a glow on Android) so nothing moves. Food's home
        // already used exactly this.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Top Header Section matching spec: Warm Orange Gradient, Delivery ETA, Address, Search Bar & Category Navigation Strip
          SliverToBoxAdapter(
            child: DeliveryHeader(
              categories: state.categories,
              onCategoryTap: (catId) =>
                  context.push(RoutePaths.subCategoryOf(catId)),
              onAllTap: () => context.go(RoutePaths.categories),
            ),
          ),

          // 2. Housefull Sale Banner matching reference design with active theme colors
          SliverToBoxAdapter(
            child: HousefullSaleBanner(
              dealProduct: _dealProducts(state).isNotEmpty ? _dealProducts(state).first : null,
              categories: state.categories,
              onCrazyDealsTap: () => context.push(
                RoutePaths.productListing,
                extra: const ProductListingArgs(title: 'Deal of the day'),
              ),
              onCategoryCardTap: (catId) =>
                  context.push(RoutePaths.subCategoryOf(catId)),
            ),
          ),

          // 3. LOWEST PRICES EVER RAIL (Sorted by lowest price first, matching reference card design)
          SliverToBoxAdapter(
            child: LowestPricesEverRow(
              products: state.sections.expand((s) => s.products).toList(),
              onProductTap: (p) => context.push(RoutePaths.productDetailsOf(p.id)),
            ),
          ),

          // 4. BESTSELLERS (Category Collage Cards matching reference design 1:1)
          SliverToBoxAdapter(
            child: BestsellersRow(
              categories: state.categories,
              onCategoryTap: (catId) =>
                  context.push(RoutePaths.subCategoryOf(catId)),
              onSeeAll: () => context.go(RoutePaths.categories),
            ),
          ),

          // 5. FEATURED THIS WEEK (Newly Launched, Price Drop, Festive Plum Cakes cards matching spec 1:1)
          SliverToBoxAdapter(
            child: FeaturedThisWeekRow(
              onCardTap: (index) => context.push(RoutePaths.productListing),
            ),
          ),

          // 4. Trust / Service Promises Strip (Farm Fresh, Free Delivery, Secure Payment, Easy Returns)
          const SliverToBoxAdapter(
            child: TrustStrip(),
          ),

          // 4. SHOP BY CATEGORY (Horizontal category cards with scroll arrow)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: ShopByCategoryRow(
                categories: state.categories,
                isLoading: state.isLoadingCategories,
                onSeeAll: () => context.go(RoutePaths.categories),
                onCategoryTap: (catId) =>
                    context.push(RoutePaths.subCategoryOf(catId)),
              ),
            ),
          ),

          // 6. ALL CATEGORY SECTIONS (4-Column Grids per category matching reference screenshot 1:1)
          SliverToBoxAdapter(
            child: AllCategorySectionsFeed(
              categories: state.categories,
              onCategoryTap: (catId) =>
                  context.push(RoutePaths.subCategoryOf(catId)),
            ),
          ),

          // 7. DEAL OF THE DAY (Discounted products with ADD TO CART 🛒)
          SliverToBoxAdapter(
            child: DealOfTheDayRow(
              products: _dealProducts(state),
              onSeeAll: () => context.push(
                RoutePaths.productListing,
                extra: const ProductListingArgs(title: 'Deal of the day'),
              ),
              onProductTap: (p) => context.push(RoutePaths.productDetailsOf(p.id)),
            ),
          ),

          // 8. Footer Trust / Feature Highlights Strip (Best Quality, Affordable Prices, Fast Delivery, 100% Secure, Easy Returns)
          const SliverToBoxAdapter(
            child: FeatureHighlightsRow(),
          ),

          // 9. Brands row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
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
          ),

          // 10. Dynamic catalog sections (Bestsellers, Trending, Buy it again, Category Rows)
          ...state.sections
              .where((s) => s.id != _dealSectionId)
              .map((section) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionHeader(
                      title: section.title,
                      subtitle: section.subtitle,
                      onSeeAll: () => context.push(
                        RoutePaths.productListing,
                        extra: ProductListingArgs(
                          title: section.title,
                        ),
                      ),
                    ),
                    ProductRow(
                      products: section.products,
                      heroTag: 'home_${section.id}',
                      onProductTap: (product) => context.push(
                        RoutePaths.productDetailsOf(product.id),
                        extra: product,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl * 2),
          ),
        ],
      ),
    );
  }

  /// The home section that backs "Deal of the day".
  static const _dealSectionId = 'flash';

  /// Products for the deal rail: the discount section when the backend built
  /// one, otherwise nothing — never a filler list.
  List<Product> _dealProducts(HomeState state) {
    for (final section in state.sections) {
      if (section.id == _dealSectionId) return section.products;
    }
    return const [];
  }
}
