import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/restaurant_model.dart';
import '../../../di/store99_providers.dart';
import '../../../domain/service/store99_service.dart';
import 'store99_state.dart';

final store99ViewModelProvider =
    NotifierProvider<Store99ViewModel, Store99State>(() {
  return Store99ViewModel();
});

class Store99ViewModel extends Notifier<Store99State> {
  late final Store99Service _service;
  static const int _pageSize = 6;

  @override
  Store99State build() {
    _service = ref.watch(store99ServiceProvider);
    // Initialize data asynchronously
    Future.microtask(() => loadInitialData());
    return const Store99State(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cuisinesResp = await _service.getCuisines();
      final brandsResp = await _service.getBrands();
      final trendingResp = await _service.getTrendingDishes(
        cuisineId: _selectedSlug,
      );
      final exploreResp = await _service.fetchProductsPage(
        cuisineId: _selectedSlug,
        page: 1,
        limit: _pageSize,
      );

      final cuisines = cuisinesResp.data ?? const [];
      final brands = brandsResp.data ?? const [];
      final trending = trendingResp.data ?? const [];
      final explore = exploreResp.data ?? const [];

      state = state.copyWith(
        cuisines: cuisines,
        brands: brands,
        trendingDishes: trending,
        exploreDishes: explore,
        page: 1,
        hasMore: explore.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load 99 Store products. Please try again.',
      );
    }
  }

  /// The keyword the catalogue filter matches for the selected chip.
  ///
  /// The chip's id is a category ObjectId; the filter regex-matches names, so
  /// sending the id found nothing and every category came back empty.
  String get _selectedSlug {
    final id = state.selectedCuisineId;
    if (id.isEmpty || id == 'all') return 'all';
    for (final c in state.cuisines) {
      if (c.id == id) return c.slug.isNotEmpty ? c.slug : c.label;
    }
    return 'all';
  }

  Future<void> selectCuisine(String cuisineId) async {
    if (state.selectedCuisineId == cuisineId) return;

    state = state.copyWith(
      selectedCuisineId: cuisineId,
      isLoading: true,
      page: 1,
      hasMore: true,
    );

    try {
      final slug = _selectedSlug;
      final exploreResp = await _service.fetchProductsPage(
        cuisineId: slug,
        page: 1,
        limit: _pageSize,
      );
      // Both rows move together: the trending strip showing another cuisine
      // beside a selected chip is the contradiction this screen had.
      final trendingResp = await _service.getTrendingDishes(cuisineId: slug);

      final explore = exploreResp.data ?? const [];

      state = state.copyWith(
        exploreDishes: explore,
        trendingDishes: trendingResp.data ?? const [],
        page: 1,
        hasMore: explore.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter by cuisine.',
      );
    }
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _service.fetchProductsPage(
        cuisineId: _selectedSlug,
        page: nextPage,
        limit: _pageSize,
      );

      final newProducts = response.data ?? const [];

      if (newProducts.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          exploreDishes: [...state.exploreDishes, ...newProducts],
          page: nextPage,
          hasMore: newProducts.length >= _pageSize,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<RestaurantModel?> getRestaurantForProduct(String restaurantId) async {
    return await _service.findRestaurant(restaurantId);
  }
}
