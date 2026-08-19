import '../../../core/errors/failure.dart';
import '../../../domain/model/banner.dart';
import '../../../domain/model/brand.dart';
import '../../../domain/model/category.dart';
import '../../../domain/model/coupon.dart';
import '../../../domain/model/product.dart';
import '../../../domain/model/seller.dart';

/// A horizontally-scrolling product row on the home screen.
class HomeSection {
  const HomeSection({
    required this.id,
    required this.title,
    required this.products,
    this.subtitle = '',
    this.categoryId,
    this.showRanks = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Product> products;

  /// Set when "See all" should open a category-filtered listing.
  final String? categoryId;

  /// Best-sellers show #1/#2 badges.
  final bool showRanks;

  bool get isEmpty => products.isEmpty;
}

/// Home is composed of independently-loading pieces, so each part carries its
/// own loading flag rather than blocking the whole page on the slowest call.
class HomeState {
  const HomeState({
    this.heroBanners = const [],
    this.topBanners = const [],
    this.categories = const [],
    this.brands = const [],
    this.sellers = const [],
    this.sections = const [],
    this.coupons = const [],
    this.isLoadingBanners = true,
    this.isLoadingCategories = true,
    this.isLoadingSections = true,
    this.isLoadingCoupons = true,
    this.isRefreshing = false,
    this.failure,
  });

  /// The header's background media: the hero collection, plus the
  /// home-promotion one, which has no slot of its own and would otherwise stop
  /// being shown anywhere.
  final List<PromoBanner> heroBanners;

  /// The promotional strip below Nearby stores.
  final List<PromoBanner> topBanners;
  final List<Category> categories;
  final List<Brand> brands;
  final List<Seller> sellers;
  final List<HomeSection> sections;

  /// Live offers from `/food/restaurant/offers`, shown as the offer cards.
  final List<Coupon> coupons;
  final bool isLoadingBanners;
  final bool isLoadingCategories;
  final bool isLoadingSections;
  final bool isLoadingCoupons;
  final bool isRefreshing;
  final Failure? failure;

  bool get isInitialLoad =>
      isLoadingSections && sections.isEmpty && categories.isEmpty;

  bool get isEmpty =>
      !isLoadingSections && sections.isEmpty && categories.isEmpty;

  /// Products of a derived section, or empty when it was dropped for having none.
  /// Sections that are not pinned to a bespoke widget above — rendered as
  /// generic product rows so nothing the catalog returned is dropped.
  static const _pinnedSectionIds = {'best-sellers', 'flash'};

  List<HomeSection> get rows =>
      sections.where((s) => !_pinnedSectionIds.contains(s.id)).toList();

  List<Product> productsOf(String sectionId) {
    for (final section in sections) {
      if (section.id == sectionId) return section.products;
    }
    return const [];
  }

  HomeState copyWith({
    List<PromoBanner>? heroBanners,
    List<PromoBanner>? topBanners,
    List<Category>? categories,
    List<Brand>? brands,
    List<Seller>? sellers,
    List<HomeSection>? sections,
    List<Coupon>? coupons,
    bool? isLoadingBanners,
    bool? isLoadingCategories,
    bool? isLoadingSections,
    bool? isLoadingCoupons,
    bool? isRefreshing,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      HomeState(
        heroBanners: heroBanners ?? this.heroBanners,
        topBanners: topBanners ?? this.topBanners,
        categories: categories ?? this.categories,
        brands: brands ?? this.brands,
        sellers: sellers ?? this.sellers,
        sections: sections ?? this.sections,
        coupons: coupons ?? this.coupons,
        isLoadingBanners: isLoadingBanners ?? this.isLoadingBanners,
        isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
        isLoadingSections: isLoadingSections ?? this.isLoadingSections,
        isLoadingCoupons: isLoadingCoupons ?? this.isLoadingCoupons,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}
