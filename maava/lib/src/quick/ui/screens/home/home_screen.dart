import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/model/banner.dart';
import '../../../navigation/route_paths.dart';
import '../../common/smart_scan.dart';
import '../../common/widgets/inputs/search_bar_widget.dart';
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
import 'widgets/promo_banners_two_column_row.dart';
import 'widgets/shop_by_category_row.dart';
import 'widgets/pinned_search_header.dart';
import 'widgets/value_props_strip.dart';
import 'widgets/active_order_card.dart';
import 'widgets/banner_carousel.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status-bar icons follow the app surface, not the banner.
      //
      // They used to be light because the header floated over a dark video; the
      // header now sits on the app surface, so light icons rendered white on
      // white and the clock vanished. Deriving from theme brightness also keeps
      // them correct in dark mode.
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: Stack(
          children: [
            SafeArea(
              // Top only: the bottom inset belongs to the nav bar, and the
              // floating cards below are positioned against the raw edge.
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
          // 1. Top Bar: Delivery location, notification bell, profile icon
          SliverToBoxAdapter(
            child: const DeliveryHeader(),
          ),

          // 2. Search Bar + 10 Min Delivery Pill Row — PINNED.
          //
          // Everything else scrolls; this stays put so search is reachable from
          // anywhere in the feed. The location header above is a normal sliver
          // and deliberately scrolls away.
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedSearchHeader(
              extent: 60,
              child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 2, AppSpacing.gutter, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      readOnly: true,
                      categories: state.categories.map((c) => c.name).toList(),
                      onTap: () => context.push(RoutePaths.search),
                      onScanTap: () => SmartScan.run(context, ref),
                      onMicTap: () => context.push('${RoutePaths.search}?voice=1'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _build10MinDeliveryBadge(),
                ],
              ),
              ),
            ),
          ),

          // 3. Hero Promo Banner Carousel (Mint Green Gradient Hero Card)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: BannerCarousel(
                banners: state.heroBanners.isNotEmpty
                    ? state.heroBanners
                    : state.topBanners,
                onTap: (banner) => _openBanner(context, banner),
              ),
            ),
          ),

          // 4. Trust / Service Promises Strip (Farm Fresh, Free Delivery, Secure Payment, Easy Returns)
          const SliverToBoxAdapter(
            child: TrustStrip(),
          ),

          // 5. SHOP BY CATEGORY (Horizontal category cards with scroll arrow)
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

          // 6. 2-Column Promotional Banners (Weekend Super Saver & 30-Min Fast Delivery)
          SliverToBoxAdapter(
            child: PromoBannersTwoColumnRow(
              topBanners: state.topBanners.isNotEmpty
                  ? state.topBanners
                  : state.heroBanners,
              onBannerTap: (banner) => _openBanner(context, banner),
              onShopNow: () => context.go(RoutePaths.categories),
              onOrderNow: () => context.push(RoutePaths.productListing),
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

  Widget _build10MinDeliveryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: context.semantic.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: Color(0xFFFACC15),
            size: 20,
          ),
          const SizedBox(width: 3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '10 Min',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                'Delivery',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: context.semantic.border,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
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
