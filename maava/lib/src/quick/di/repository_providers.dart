import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../di/network_providers.dart' as core_di;
import '../../presentation/auth/viewmodels/auth_viewmodel.dart';
import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../core/local_storage/local_storage.dart';
import '../core/network/api_client.dart';
import '../core/network/shared_api_client.dart';
import '../data/repository_impl/api_cart_repository.dart';
import '../data/repository_impl/api_catalog_content_repository.dart';
import '../data/repository_impl/api_category_repository.dart';
import '../data/repository_impl/api_coupon_repository.dart';
import '../data/repository_impl/api_chat_repository.dart';
import '../data/repository_impl/api_notification_repository.dart';
import '../data/repository_impl/api_order_repository.dart';
import '../data/repository_impl/api_product_repository.dart';
import '../data/repository_impl/api_review_repository.dart';
import '../data/repository_impl/api_wishlist_repository.dart';
import '../data/repository_impl/google_place_repository.dart';
import '../data/repository_impl/quick_auth_repository.dart';
import '../domain/model/user.dart';
import '../domain/repository/auth_repository.dart';
import '../domain/repository/cart_repository.dart';
import '../domain/repository/catalog_content_repository.dart';
import '../domain/repository/category_repository.dart';
import '../domain/repository/coupon_repository.dart';
import '../domain/repository/chat_repository.dart';
import '../domain/repository/notification_repository.dart';
import '../domain/repository/order_repository.dart';
import '../domain/repository/place_repository.dart';
import '../domain/repository/product_repository.dart';
import '../domain/repository/review_repository.dart';
import '../domain/repository/wishlist_repository.dart';
import '../platform/location/location_service.dart';
import '../platform/payment/razorpay_checkout.dart';
import '../platform/permission/permission_service.dart';
import '../platform/realtime/realtime_socket.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final localStorageProvider = Provider<LocalStorage>(
  (ref) => throw UnimplementedError('localStorageProvider must be overridden'),
);

/// Built from the app-wide constants: same host as the food vertical, the
/// vertical itself is selected by the `/quick/...` path prefix in [ApiPaths].
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig(
    apiBaseUrl: AppConstants.baseUrl,
    mapsApiKey: AppConstants.mapKey,
    environment: kReleaseMode ? 'production' : 'development',
    enableNetworkLogs: !kReleaseMode,
  ),
);

/// The single transport every repository shares — an adapter over the
/// app-wide client, so tokens, refresh and caching are shared with the food
/// vertical.
final apiClientProvider = Provider<ApiClient>(
  (ref) => SharedApiClient(ref.watch(core_di.apiClientProvider)),
);

// ── Platform ────────────────────────────────────────────────────────────────

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const GeolocatorPermissionService());

/// Google Places + Geocoding. Concrete type is exposed as well so the address
/// screen can open and close an autocomplete billing session.
final googlePlaceRepositoryProvider = Provider<GooglePlaceRepository>(
  (ref) => GooglePlaceRepository(ref.watch(appConfigProvider)),
);

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => ref.watch(googlePlaceRepositoryProvider),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(
    ref.watch(permissionServiceProvider),
    ref.watch(placeRepositoryProvider),
  ),
);

/// Razorpay checkout. Disposed with the container so a half-open sheet cannot
/// outlive the app session.
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  final gateway = RazorpayCheckout();
  ref.onDispose(gateway.dispose);
  return gateway;
});

// ── Repositories (interface → API implementation) ───────────────────────────

/// Identity delegates to the shared MAAVA session; wallet calls go through
/// the shared transport against the quick vertical.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  User? currentQuickUser() {
    final u = ref.read(authViewModelProvider).value;
    return u == null ? null : quickUserFromShared(u);
  }

  User requireQuickUser() {
    final u = currentQuickUser();
    if (u == null) throw const UnauthorizedException('Please sign in again.');
    return u;
  }

  return QuickAuthRepository(
    ref.watch(apiClientProvider),
    cachedUserFn: currentQuickUser,
    refreshUserFn: () async {
      await ref.read(authViewModelProvider.notifier).refreshProfile();
      return requireQuickUser();
    },
    updateProfileFn: ({name, email, gender, dateOfBirth}) async {
      await ref.read(authViewModelProvider.notifier).updateProfile(
            name: name,
            email: email,
            gender: gender,
            dateOfBirth: dateOfBirth?.toIso8601String().split('T').first,
          );
      return requireQuickUser();
    },
    signOutFn: () => ref.read(authViewModelProvider.notifier).logout(),
    deleteAccountFn: () async {
      final notifier = ref.read(authViewModelProvider.notifier);
      final ok = await notifier.deleteAccount();
      if (!ok) {
        throw ServerException(notifier.lastError ?? 'Could not delete the account.');
      }
    },
  );
});

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ApiProductRepository(ref.watch(apiClientProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => ApiCategoryRepository(
    ref.watch(apiClientProvider),
    productRepository: ref.watch(productRepositoryProvider),
  ),
);

final catalogContentRepositoryProvider = Provider<CatalogContentRepository>(
  (ref) => ApiCatalogContentRepository(ref.watch(apiClientProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => ApiCartRepository(
    ref.watch(apiClientProvider),
    ref.watch(localStorageProvider),
  ),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => ApiOrderRepository(ref.watch(apiClientProvider)),
);


final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => ApiCouponRepository(ref.watch(apiClientProvider)),
);

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => ApiWishlistRepository(ref.watch(apiClientProvider)),
);

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ApiReviewRepository(ref.watch(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => ApiNotificationRepository(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ApiChatRepository(ref.watch(apiClientProvider)),
);

/// One shared chat socket for the whole app. It connects on first use with the
/// current access token and the API origin, and is torn down with the app.
final realtimeSocketProvider = Provider<RealtimeSocket>((ref) {
  final service = RealtimeSocket();
  ref.watch(core_di.tokenStorageProvider).accessToken.then((token) {
    if (token != null && token.isNotEmpty) {
      service.connect(token: token, origin: AppConstants.socketUrl);
    }
  });
  ref.onDispose(service.dispose);
  return service;
});
