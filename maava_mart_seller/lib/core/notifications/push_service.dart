import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:maava_mart_seller/core/logging/push_log.dart';
import 'package:maava_mart_seller/core/logging/startup_log.dart';

/// Runs in its own isolate when a message arrives with the app backgrounded or
/// killed, so nothing from the running app is in scope here.
///
/// It exists to make the delivery visible in a debug run: the backend sends the
/// new-order alert as two messages (a notification leg Android draws by itself,
/// then a data-only leg), and without this the data-only leg leaves no trace at
/// all — making "the push never arrived" indistinguishable from "it arrived and
/// the tap did nothing".
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  pushLog('background message', PushService.describe(message));
}

/// Firebase Cloud Messaging: registration, and routing a tapped new-order
/// notification to the order it refers to.
///
/// There is no separate "save my token" call at sign-in: the backend attaches
/// [token] to the seller on `verify-otp` and detaches it on `logout`. See
/// `auth_controller.dart` for both ends and `app.dart` for the re-registration
/// that covers an already-signed-in seller.
class PushService {
  const PushService._();

  /// The device's FCM token, or null when push is unavailable — Firebase not
  /// configured for this platform, or the seller declined the permission.
  static String? token;

  /// The `type` the backend stamps on a new-order push. Defined by
  /// `notifyRestaurantNewOrder` in the backend's `order.helpers.js`; this app
  /// reads that payload rather than asking for a new one.
  static const String newOrderType = 'new_order';

  /// Best-effort by design. Push is an enhancement; a missing
  /// `GoogleService-Info.plist` or a denied permission must never stop the
  /// seller from signing in and working.
  ///
  /// [onOrderTap] fires with the order id from a tapped new-order
  /// notification, in every app state — foreground, background and killed.
  /// [onForegroundMessage] receives the new-order id when that is what
  /// arrived, and null for every other push — so the caller can sound the
  /// new-order alert without having to know the payload format, and can never
  /// sound it for an unrelated notification.
  static Future<void> init({
    void Function(String? newOrderId)? onForegroundMessage,
    void Function(String token)? onToken,
    void Function(String orderId)? onOrderTap,
  }) async {
    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;
      // Android 13+ and iOS both gate the notification tray behind this. It is
      // a no-op on older Android.
      final settings = await messaging.requestPermission();
      pushLog('permission', settings.authorizationStatus.name);

      // Must be registered before any await on a message stream, and only from
      // the main isolate.
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      token = await messaging.getToken();
      startupLog('push: token', token == null ? 'none' : 'acquired');
      // Tail only — enough to match against the backend's stored token in a
      // debug session without putting a working push credential in the log.
      final tail = token == null
          ? 'none'
          : '…${token!.length > 12 ? token!.substring(token!.length - 12) : token!}';
      pushLog('token', tail);
      if (token != null) onToken?.call(token!);

      // Tokens rotate on app restore or a cleared cache. The old one stops
      // delivering, so the backend has to hear about the new one immediately —
      // waiting for the next sign-in would silently drop every push until then.
      messaging.onTokenRefresh.listen((value) {
        token = value;
        pushLog('token refreshed');
        onToken?.call(value);
      });

      FirebaseMessaging.onMessage.listen((message) {
        pushLog('foreground message', describe(message));
        // Deliberately does not navigate. The seller is already looking at
        // something; yanking them to another screen mid-task is not theirs to
        // ask for. The list and inbox refresh instead, and the tray copy is
        // still there to tap.
        final isNewOrder = (message.data['type'] ?? '').toString() == newOrderType;
        onForegroundMessage?.call(isNewOrder ? orderIdOf(message) : null);
      });

      // App alive but backgrounded — the tap resumes it and delivers here.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        pushLog('notification tapped (background)', describe(message));
        _routeTap(message, onOrderTap);
      });

      // App was killed: the message that launched it is waiting here, once
      // only. Nothing else reports this case.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        pushLog('app launched from notification', describe(initial));
        _routeTap(initial, onOrderTap);
      }
    } catch (error) {
      // Most often: no google-services.json / GoogleService-Info.plist for this
      // platform. Logged rather than swallowed so it is visible in a debug run.
      startupLog('push: init failed', error);
      pushLog('init failed', error);
    }
  }

  static void _routeTap(
    RemoteMessage message,
    void Function(String orderId)? onOrderTap,
  ) {
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    final orderId = orderIdOf(message);

    pushLog('notification type', type.isEmpty ? '<none>' : type);
    pushLog('order id', orderId ?? '<none>');

    if (type != newOrderType || orderId == null) {
      // Any other push just opens the app. Guessing a destination from a
      // payload this app does not understand is how sellers end up on a blank
      // screen with no way back to what they were doing.
      pushLog('navigation destination', 'none (not a new-order push)');
      return;
    }

    onOrderTap?.call(orderId);
  }

  /// The Mongo id the order routes are keyed by.
  ///
  /// `orderId` is what the backend sends; `orderMongoId` is the same value
  /// under an older name. `orderDisplayId` is deliberately not a fallback — it
  /// is the human-facing reference (`order_id`) and the API would 404 on it.
  static String? orderIdOf(RemoteMessage message) {
    for (final key in const ['orderId', 'orderMongoId']) {
      final value = (message.data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// Compact one-line summary for the debug log. Only the fields that decide
  /// routing — the payload also carries the rendered body, which is long and
  /// tells us nothing about why a tap went astray.
  static String describe(RemoteMessage message) {
    final data = message.data;
    return 'type=${data['type'] ?? '-'} '
        'orderId=${data['orderId'] ?? '-'} '
        'display=${data['orderDisplayId'] ?? '-'} '
        'hasNotification=${message.notification != null}';
  }
}
