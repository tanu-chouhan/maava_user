import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_user_application/features/menu_items/data/menu_repository.dart';
import 'package:food_user_application/features/menu_items/domain/food_item_model.dart';
import 'package:food_user_application/features/menu_items/domain/menu_section_model.dart';

class MenuController extends AsyncNotifier<List<MenuSectionModel>> {
  @override
  Future<List<MenuSectionModel>> build() {
    return ref.read(menuRepositoryProvider).getMenu();
  }

  /// Deliberately does not flip to [AsyncValue.loading] first: doing so blanked
  /// the whole menu after every add/edit, so items looked like they vanished.
  /// The list stays on screen until the refetch resolves.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(menuRepositoryProvider).getMenu(),
    );
  }

  Future<void> createFood({
    required String name,
    required String foodType,
    String description = '',
    required double price,
    double otherPrice = 0,
    String image = '',
    String? categoryId,
    bool isAvailable = true,
    bool isRecommended = false,
    String preparationTime = '',
    List<FoodVariant> variants = const [],
  }) async {
    await ref
        .read(menuRepositoryProvider)
        .createFood(
          name: name,
          foodType: foodType,
          description: description,
          price: price,
          otherPrice: otherPrice,
          image: image,
          categoryId: categoryId,
          isAvailable: isAvailable,
          isRecommended: isRecommended,
          preparationTime: preparationTime,
          variants: variants,
        );
    await refresh();
  }

  Future<void> updateFood(
    String id, {
    String? name,
    String? foodType,
    String? description,
    double? price,
    double? otherPrice,
    String? image,
    String? categoryId,
    bool? isAvailable,
    bool? isRecommended,
    String? preparationTime,
    List<FoodVariant>? variants,
  }) async {
    await ref
        .read(menuRepositoryProvider)
        .updateFood(
          id,
          name: name,
          foodType: foodType,
          description: description,
          price: price,
          otherPrice: otherPrice,
          image: image,
          categoryId: categoryId,
          isAvailable: isAvailable,
          isRecommended: isRecommended,
          preparationTime: preparationTime,
          variants: variants,
        );
    await refresh();
  }

  /// Optimistic toggle so the switch flips instantly instead of waiting on
  /// a full menu refetch; reverts (via [refresh]) if the request fails.
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data([
        for (final section in current)
          MenuSectionModel(
            id: section.id,
            categoryId: section.categoryId,
            name: section.name,
            image: section.image,
            items: [
              for (final item in section.items)
                if (item.id == id)
                  item.copyWith(isAvailable: isAvailable)
                else
                  item,
            ],
          ),
      ]);
    }
    try {
      await ref
          .read(menuRepositoryProvider)
          .updateFood(id, isAvailable: isAvailable);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

final menuControllerProvider =
    AsyncNotifierProvider<MenuController, List<MenuSectionModel>>(
      MenuController.new,
    );
