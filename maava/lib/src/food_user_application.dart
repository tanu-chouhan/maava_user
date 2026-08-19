import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:maava/src/presentation/branding/app_colors.dart';
import 'package:maava/src/presentation/branding/app_theme.dart';
import 'package:maava/src/presentation/branding/theme_provider.dart';
import 'package:maava/src/presentation/navigation/app_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/constants/app_constants.dart';
import 'core/error/failures.dart';
import 'di/order_providers.dart';
import 'di/push_providers.dart';
import 'platform/notifications/push_service.dart';
import 'presentation/auth/viewmodels/auth_viewmodel.dart';
import 'presentation/navigation/home_first_back_button_dispatcher.dart';
import 'shared/theme/active_brand.dart';

class FoodUserApplication extends ConsumerStatefulWidget {
  const FoodUserApplication({super.key});

  @override
  ConsumerState<FoodUserApplication> createState() => _FoodUserApplicationState();
}

class _FoodUserApplicationState extends ConsumerState<FoodUserApplication> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final HomeFirstBackButtonDispatcher _backButtonDispatcher =
      HomeFirstBackButtonDispatcher();

  @override
  void initState() {
    super.initState();
    // Push listeners are wired once for the app's lifetime. Deep links are
    // handed to the router rather than the service touching navigation itself.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pushService = ref.read(pushServiceProvider);
      await pushService.initialize(
        onDeepLink: _handleDeepLink,
        onPermanentlyDenied: _showPermissionExplanationDialog,
      );

      final user = ref.read(authViewModelProvider).value;
      await pushService.performAppStartCheck(
        isLoggedIn: user != null,
        user: user,
      );
    });
  }

  void _showPermissionExplanationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Text(
          'Notifications are required to receive real-time updates about your food orders (Order Accepted, Out for Delivery, Delivered, etc.). Please enable notifications in App Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Routes an order push to the tracking screen.
  ///
  /// The push payload carries no vertical, and the same account orders from
  /// both. The food order is fetched first; a 404 means the id belongs to the
  /// quick-commerce vertical, whose tracking screen lives under /quick.
  Future<void> _handleDeepLink(PushDeepLink link) async {
    final orderId = link.trackableOrderId;
    if (!link.isOrderEvent || orderId == null || orderId.isEmpty) return;
    var isFoodOrder = true;
    try {
      await ref.read(orderRemoteDataSourceProvider).getOrder(orderId);
    } on NotFoundFailure {
      isFoodOrder = false;
    } catch (_) {
      // Network trouble — assume food (today's behavior) rather than dropping
      // the tap on the floor.
    }
    // Route is declared as /orders/track/:id — a path param, not a query.
    ref.read(routerProvider).push(
          isFoodOrder ? '/orders/track/$orderId' : '/quick/order/$orderId/track',
        );
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(routerProvider);

    // Register the device against the account on login; unregister on logout so
    // the next user of the device is not targeted.
    ref.listen(authViewModelProvider, (previous, next) {
      final was = previous?.value?.id;
      final now = next.value?.id;
      if (was == now && now != null) return;
      final push = ref.read(pushServiceProvider);
      if (now != null) {
        push.registerToken(user: next.value);
      } else if (previous?.value != null && now == null) {
        push.unregisterToken();
      }
    });

    // Rebuilds MaterialApp — and therefore every screen under it — whenever the
    // active module or the picked palette changes, which is what makes the
    // shared screens recolour the instant the user flips Food <-> Quick.
    ref.watch(activeBrandProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        title: AppConstants.title,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ref.watch(themeProvider),
        // Unpacked instead of `routerConfig: goRouter` so a custom
        // backButtonDispatcher can be supplied — MaterialApp.router asserts
        // routerConfig and backButtonDispatcher are mutually exclusive.
        routeInformationProvider: goRouter.routeInformationProvider,
        routeInformationParser: goRouter.routeInformationParser,
        routerDelegate: goRouter.routerDelegate,
        backButtonDispatcher: _backButtonDispatcher,
      ),
    );
  }
}

