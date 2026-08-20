import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_user_application/core/network/dio_client.dart';
import 'package:food_user_application/features/menu_items/domain/food_item_model.dart';
import 'package:food_user_application/features/menu_items/domain/menu_section_model.dart';

class MenuRepository {
  MenuRepository(this._dio);

  final Dio _dio;

  Future<List<MenuSectionModel>> getMenu() async {
    final response = await _dio.get('/food/restaurant/menu');
    final data = Map<String, dynamic>.from(response.data as Map);
    final menu = Map<String, dynamic>.from(data['menu'] as Map);
    final sections = (menu['sections'] as List? ?? []);
    return sections
        .map(
          (e) => MenuSectionModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<FoodItemModel> createFood({
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
    final response = await _dio.post(
      '/food/restaurant/foods',
      data: {
        'name': name,
        'foodType': foodType,
        'description': description,
        if (variants.isEmpty) 'price': price,
        if (variants.isEmpty && otherPrice > 0) 'otherPrice': otherPrice,
        if (variants.isNotEmpty)
          'variants': [for (final v in variants) v.toJson()],
        'image': image,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        'isAvailable': isAvailable,
        'isRecommended': isRecommended,
        'preparationTime': preparationTime,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return FoodItemModel.fromJson(
      Map<String, dynamic>.from(data['food'] as Map),
    );
  }

  Future<FoodItemModel> updateFood(
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
    // The API rejects a base price on an item that has variants
    // ("Update variants instead of base price"), and requires one when the
    // last variant is removed. Deciding here keeps every caller safe.
    final hasVariants = variants != null && variants.isNotEmpty;
    final response = await _dio.patch(
      '/food/restaurant/foods/$id',
      data: {
        if (name != null) 'name': name,
        if (foodType != null) 'foodType': foodType,
        if (description != null) 'description': description,
        if (price != null && !hasVariants) 'price': price,
        if (otherPrice != null && !hasVariants) 'otherPrice': otherPrice,
        if (variants != null)
          'variants': [for (final v in variants) v.toJson()],
        if (image != null) 'image': image,
        if (categoryId != null) 'categoryId': categoryId,
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (isRecommended != null) 'isRecommended': isRecommended,
        if (preparationTime != null) 'preparationTime': preparationTime,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return FoodItemModel.fromJson(
      Map<String, dynamic>.from(data['food'] as Map),
    );
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(dioProvider));
});
