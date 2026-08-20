import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_user_application/config/theme/app_colors.dart';
import 'package:food_user_application/core/network/api_exception.dart';
import 'package:food_user_application/features/menu_categories/presentation/controllers/category_controller.dart';
import 'package:food_user_application/features/menu_items/domain/food_item_model.dart';
import 'package:food_user_application/features/menu_items/presentation/controllers/menu_controller.dart';
import 'package:food_user_application/features/registration/presentation/widgets/image_picker_tile.dart';
import 'package:food_user_application/features/registration/presentation/widgets/labeled_text_field.dart';
import 'package:food_user_application/features/registration/presentation/widgets/segmented_toggle.dart';
import 'package:food_user_application/features/restaurant_profile/data/restaurant_repository.dart';
import 'package:food_user_application/features/restaurant_profile/presentation/controllers/restaurant_profile_controller.dart';

Future<void> showFoodItemFormSheet(
  BuildContext context, {
  FoodItemModel? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FoodItemFormSheet(existing: existing),
  );
}

class FoodItemFormSheet extends ConsumerStatefulWidget {
  const FoodItemFormSheet({super.key, this.existing});

  final FoodItemModel? existing;

  @override
  ConsumerState<FoodItemFormSheet> createState() => _FoodItemFormSheetState();
}

class _FoodItemFormSheetState extends ConsumerState<FoodItemFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _price = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.price.toStringAsFixed(0)
        : '',
  );
  late final _otherPrice = TextEditingController(
    text: widget.existing?.otherPrice.toString() ?? '',
  );
  late final _preparationTime = TextEditingController(
    text: widget.existing?.preparationTime ?? '',
  );
  late bool _isVeg = widget.existing?.isVeg ?? true;
  late bool _isAvailable = widget.existing?.isAvailable ?? true;
  late bool _isRecommended = widget.existing?.isRecommended ?? false;
  String? _categoryId;
  String _existingImageUrl = '';
  XFile? _pickedImage;
  bool _isSaving = false;

  final List<Map<String, TextEditingController>> _variants = [];

  /// Parallel to [_variants]; holds the server `_id` of each row ('' when new)
  /// so editing keeps the existing variant rows rather than replacing them.
  final List<String> _variantIds = [];

  void _addVariant() {
    setState(() {
      _variantIds.add('');
      _variants.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
        'otherPrice': TextEditingController(),
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variantIds.removeAt(index);
      final v = _variants.removeAt(index);
      for (final c in v.values) {
        c.dispose();
      }
    });
  }

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
    _existingImageUrl = widget.existing?.image ?? '';
    for (final v in widget.existing?.variants ?? const <FoodVariant>[]) {
      _variantIds.add(v.id);
      _variants.add({
        'name': TextEditingController(text: v.name),
        'price': TextEditingController(text: _trimNum(v.price)),
        'otherPrice': TextEditingController(
          text: v.otherPrice > 0 ? _trimNum(v.otherPrice) : '',
        ),
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _otherPrice.dispose();
    _preparationTime.dispose();
    for (final v in _variants) {
      for (final c in v.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// 250.0 -> '250', 250.5 -> '250.5' (prices are entered as plain numbers).
  static String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Reads the variant rows, or null when one of them is invalid.
  /// The API requires every variant to have a name and a price above 0.
  List<FoodVariant>? _collectVariants() {
    final variants = <FoodVariant>[];
    for (var i = 0; i < _variants.length; i++) {
      final row = _variants[i];
      final name = row['name']!.text.trim();
      if (name.isEmpty) {
        _showError('Give variant ${i + 1} a name, or remove it.');
        return null;
      }
      final price = double.tryParse(row['price']!.text.trim());
      if (price == null || price <= 0) {
        _showError('Enter a price above 0 for "$name".');
        return null;
      }
      variants.add(
        FoodVariant(
          id: _variantIds[i],
          name: name,
          price: price,
          otherPrice: double.tryParse(row['otherPrice']!.text.trim()) ?? 0,
        ),
      );
    }
    return variants;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showError('Item name is required.');
      return;
    }

    final variants = _collectVariants();
    if (variants == null) return;

    // With variants the server derives the price from them, and rejects a base
    // price outright — so only validate/send one when there are no variants.
    double? price;
    if (variants.isEmpty) {
      price = double.tryParse(_price.text.trim());
      if (price == null || price < 0) {
        _showError('Enter a valid price.');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      var imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(restaurantRepositoryProvider)
            .uploadAttachment(_pickedImage!, folder: 'menu');
      }
      final isPureVeg =
          ref.read(restaurantProfileControllerProvider).value?.pureVegRestaurant ??
          false;
      final foodType = (_isVeg || isPureVeg) ? 'Veg' : 'Non-Veg';
      final otherPrice = double.tryParse(_otherPrice.text.trim()) ?? 0;

      if (_isEditing) {
        await ref
            .read(menuControllerProvider.notifier)
            .updateFood(
              widget.existing!.id,
              name: name,
              foodType: foodType,
              description: _description.text.trim(),
              price: price,
              otherPrice: variants.isEmpty ? otherPrice : null,
              image: imageUrl,
              categoryId: _categoryId ?? '',
              variants: variants,
              isAvailable: _isAvailable,
              isRecommended: _isRecommended,
              preparationTime: _preparationTime.text.trim(),
            );
      } else {
        await ref
            .read(menuControllerProvider.notifier)
            .createFood(
              name: name,
              foodType: foodType,
              description: _description.text.trim(),
              price: price ?? 0,
              otherPrice: otherPrice,
              image: imageUrl,
              categoryId: _categoryId,
              variants: variants,
              isAvailable: _isAvailable,
              isRecommended: _isRecommended,
              preparationTime: _preparationTime.text.trim(),
            );
      }
      if (mounted) {
        // Resolve the messenger before popping — afterwards this context is
        // defunct and the confirmation silently never appears.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Item updated — pending re-approval.'
                  : 'Item submitted for approval.',
            ),
          ),
        );
      }
    } catch (e) {
      _showError(
        e is ApiException
            ? e.message
            : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ref.watch(restaurantProfileControllerProvider).value;
    final isPureVeg = restaurant?.pureVegRestaurant ?? false;

    final categoriesAsync = ref.watch(categoryControllerProvider);
    final approvedCategories = (categoriesAsync.value ?? [])
        .where(
          (c) =>
              c.isApproved &&
              c.isActive &&
              (!isPureVeg || c.foodTypeScope == 'Veg'),
        )
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Item' : 'Add Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LabeledTextField(
              label: 'Item name',
              controller: _name,
              hint: 'e.g. Paneer Tikka',
              required: true,
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Description',
              controller: _description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Item price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (_variants.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Customers will see the lowest variant price first.',
                        style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_variants.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Price *',
                      controller: _price,
                      required: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Strike price (optional)',
                      controller: _otherPrice,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      prefixText: '₹ ',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Variants',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Optional. Add multiple names and prices like Half, Full, Small, Large.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _addVariant,
                        icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                        label: const Text('Add variant', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                  if (_variants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...List.generate(_variants.length, (index) {
                      final variant = _variants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          color: Colors.grey.shade50,
                        ),
                        // Name on its own row, prices below. Three fields side
                        // by side left each price ~100px — the '₹' prefix filled
                        // it and the typed amount scrolled out of sight, so the
                        // field looked empty even once you had entered a price.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: LabeledTextField(
                                    label: 'Variant name',
                                    controller: variant['name']!,
                                    hint: 'e.g. Large',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () => _removeVariant(index),
                                  tooltip: 'Remove variant',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: LabeledTextField(
                                    label: 'Variant price *',
                                    controller: variant['price']!,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    prefixText: '₹ ',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LabeledTextField(
                                    label: 'Strike price',
                                    controller: variant['otherPrice']!,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    prefixText: '₹ ',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Food type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedToggle<bool>(
              options: const [
                SegmentedOption(true, 'Veg'),
                SegmentedOption(false, 'Non-Veg'),
              ],
              value: isPureVeg || _isVeg,
              onChanged: isPureVeg ? (_) {} : (v) => setState(() => _isVeg = v),
            ),
            if (isPureVeg) ...[
              const SizedBox(height: 6),
              const Text(
                'Your restaurant is pure veg — all items must be Veg.',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Category (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: approvedCategories.any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  hint: const Text('No category'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No category'),
                    ),
                    ...approvedCategories.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Preparation time (mins)',
              controller: _preparationTime,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ImagePickerTile(
              label: 'Item photo',
              image: _pickedImage,
              height: 120,
              onPick: () async {
                final file = await pickImageWithSourceSheet(context);
                if (file != null) setState(() => _pickedImage = file);
              },
              onRemove: () => setState(() {
                _pickedImage = null;
                _existingImageUrl = '';
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Available for order',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mark as recommended',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: _isRecommended,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isRecommended = v),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save' : 'Create',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
