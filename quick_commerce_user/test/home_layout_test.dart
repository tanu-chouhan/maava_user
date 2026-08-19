import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_commerce_user/core/local_storage/local_storage.dart';
import 'package:quick_commerce_user/core/theme/app_colors.dart';
import 'package:quick_commerce_user/core/theme/app_theme.dart';
import 'package:quick_commerce_user/di/repository_providers.dart';
import 'package:quick_commerce_user/domain/model/coupon.dart';
import 'package:quick_commerce_user/domain/model/product.dart';
import 'package:quick_commerce_user/ui/common/widgets/cards/product_card.dart';
import 'package:quick_commerce_user/ui/screens/home/widgets/feature_highlights_row.dart';
import 'package:quick_commerce_user/ui/screens/home/widgets/offer_coupons_row.dart';

/// The redesigned home rows are dense — four promises across a phone, two promo
/// cards side by side. A RenderFlex overflow throws in a widget test, so
/// pumping each at the narrowest phone width is what keeps the layout honest.
void main() {
  const narrowPhone = Size(320, 720);

  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light(AppThemeFlavor.harvest),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Future<void> pumpAt(WidgetTester tester, Widget child, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(child));
  }

  /// The offer and hero headlines render as two-tone [RichText], so their copy
  /// has to be read out of the span tree rather than matched as a Text widget.
  Finder richTextReading(String plain) => find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().replaceAll('\n', ' ').trim() == plain,
      );

  Coupon coupon(String id, String title, {double minOrder = 0}) => Coupon(
        id: id,
        code: 'SAVE$id',
        title: title,
        discountType: DiscountType.percentage,
        discountValue: 30,
        minOrderValue: minOrder,
      );

  testWidgets('the service promises fit a narrow phone', (tester) async {
    await pumpAt(tester, const FeatureHighlightsRow(), narrowPhone);
    expect(tester.takeException(), isNull);
    expect(find.text('Farm Fresh'), findsOneWidget);
  });

  testWidgets('the benefits panel fits a narrow phone', (tester) async {
    await pumpAt(tester, const ServiceBenefitsPanel(), narrowPhone);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two offers lay out side by side', (tester) async {
    await pumpAt(
      tester,
      OfferCouponsRow(
        coupons: [
          coupon('1', 'Weekend Super Saver', minOrder: 149),
          coupon('2', 'Get delivery in 30 minutes'),
        ],
      ),
      narrowPhone,
    );
    expect(tester.takeException(), isNull);
    // Both cards render the backend's own copy, not a canned promotion.
    expect(richTextReading('Weekend Super Saver'), findsOneWidget);
    expect(find.text('Get delivery in 30 minutes'), findsOneWidget);
    expect(find.textContaining('₹149'), findsOneWidget);
  });

  testWidgets('a single offer takes the full width', (tester) async {
    await pumpAt(
      tester,
      OfferCouponsRow(coupons: [coupon('1', 'Only offer')]),
      narrowPhone,
    );
    expect(tester.takeException(), isNull);
    expect(richTextReading('Only offer'), findsOneWidget);
    expect(find.text('ORDER NOW'), findsNothing);
  });

  testWidgets('no offers renders nothing rather than a filler card',
      (tester) async {
    await pumpAt(tester, const OfferCouponsRow(), narrowPhone);
    expect(tester.takeException(), isNull);
    expect(find.text('SHOP NOW'), findsNothing);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('a coupon with no threshold falls back to its code',
      (tester) async {
    await pumpAt(
      tester,
      OfferCouponsRow(coupons: [coupon('9', 'Flat thirty')]),
      narrowPhone,
    );
    expect(find.textContaining('SAVE9'), findsOneWidget);
  });

  testWidgets('a product card fits the tightest grid cell it is used in',
      (tester) async {
    // 0.52 is the narrowest aspect ratio any grid asks of this card
    // (sub-category, wishlist); a two-column phone gives it ~150x288.
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const product = Product(
      id: 'p1',
      name: 'A product with a name long enough to need truncating',
      price: 79,
      mrp: 99,
      packSize: '1 kg',
      sellerId: 's1',
      imageUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(_MemoryStorage())],
        child: MaterialApp(
          theme: AppTheme.light(AppThemeFlavor.harvest),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 288,
                child: ProductCard(product: product, onTap: _noop, width: 150),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ADD TO CART'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
  });
}

void _noop() {}

/// In-memory [LocalStorage] so the cart controller can initialise offline.
class _MemoryStorage implements LocalStorage {
  final _values = <String, Object>{};

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String> getStringList(String key) =>
      (_values[key] as List<String>?) ?? const [];

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
