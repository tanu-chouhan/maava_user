class FoodVariant {
  const FoodVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.otherPrice,
  });

  factory FoodVariant.fromJson(Map<String, dynamic> json) {
    num? asNum(dynamic v) => v is num ? v : num.tryParse((v ?? '').toString());
    return FoodVariant(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: asNum(json['price'])?.toDouble() ?? 0,
      otherPrice: asNum(json['otherPrice'])?.toDouble() ?? 0,
    );
  }

  final String id;
  final String name;
  final double price;
  final double otherPrice;

  /// Shape the backend accepts (`variants: [{name, price, otherPrice}]`).
  /// `_id` is echoed back so the server keeps the same variant rows on edit.
  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) '_id': id,
    'name': name,
    'price': price,
    if (otherPrice > 0) 'otherPrice': otherPrice,
  };
}

class FoodItemModel {
  FoodItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.otherPrice,
    required this.image,
    required this.foodType,
    required this.isAvailable,
    required this.isRecommended,
    required this.approvalStatus,
    required this.rejectionReason,
    required this.preparationTime,
    this.variants = const [],
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    num? asNum(dynamic v) => v is num ? v : num.tryParse((v ?? '').toString());
    return FoodItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: (json['categoryName'] ?? json['category'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: asNum(json['price'])?.toDouble() ?? 0,
      otherPrice: asNum(json['otherPrice'])?.toDouble() ?? 0,
      image: (json['image'] ?? '').toString(),
      foodType: (json['foodType'] ?? 'Non-Veg').toString(),
      isAvailable: json['isAvailable'] != false,
      isRecommended: json['isRecommended'] == true,
      approvalStatus: (json['approvalStatus'] ?? 'pending').toString(),
      rejectionReason: (json['rejectionReason'] ?? '').toString(),
      preparationTime: (json['preparationTime'] ?? '').toString(),
      variants: ((json['variants'] ?? json['variations']) as List? ?? [])
          .map((e) => FoodVariant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String id;
  final String? categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double price;
  final double otherPrice;
  final String image;
  final String foodType; // Veg | Non-Veg
  final bool isAvailable;
  final bool isRecommended;
  final String approvalStatus; // pending | approved | rejected
  final String rejectionReason;
  final String preparationTime;
  final List<FoodVariant> variants;

  bool get hasVariants => variants.isNotEmpty;

  /// Use this instead of rebuilding the model field-by-field: a manual
  /// reconstruction silently drops any field the caller forgets (that is how
  /// an optimistic availability toggle used to wipe [variants] in memory,
  /// which then saved an item's variants away on the next edit).
  FoodItemModel copyWith({bool? isAvailable}) => FoodItemModel(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    name: name,
    description: description,
    price: price,
    otherPrice: otherPrice,
    image: image,
    foodType: foodType,
    isAvailable: isAvailable ?? this.isAvailable,
    isRecommended: isRecommended,
    approvalStatus: approvalStatus,
    rejectionReason: rejectionReason,
    preparationTime: preparationTime,
    variants: variants,
  );

  bool get isVeg => foodType == 'Veg';
  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
}
