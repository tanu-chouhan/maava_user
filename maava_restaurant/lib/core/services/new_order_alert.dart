import 'dart:convert';

import 'package:food_user_application/core/services/local_notification_service.dart';

/// Rings the new-order alert whichever transport delivered the order.
///
/// Two things report a new order: the FCM push and the `new_order` socket
/// event. Only the push ever rang — the socket handler just refreshed the list
/// silently — so whenever push did not arrive (no server credential, OEM
/// throttling, token not yet registered, Play Services missing) an order
/// landed with no sound at all and the restaurant had to be watching the
/// screen. Both paths now ring through here.
///
/// The same order usually arrives on both transports, so [claim] keeps one
/// ring per order instead of two.
class NewOrderAlert {
  NewOrderAlert._();

  static const _dedupeWindow = Duration(minutes: 2);
  static final Map<String, DateTime> _alerted = {};

  /// Claims [orderId] for ringing; false when it already rang recently.
  ///
  /// The FCM background isolate keeps its own copy of this map, but it only
  /// runs while the app is backgrounded — where the socket is not delivering —
  /// so the two copies never race in practice.
  static bool claim(String? orderId) {
    if (orderId == null || orderId.isEmpty) return true;
    final now = DateTime.now();
    _alerted.removeWhere((_, at) => now.difference(at) > _dedupeWindow);
    if (_alerted.containsKey(orderId)) return false;
    _alerted[orderId] = now;
    return true;
  }

  /// Order id out of a `new_order` socket payload (the raw order document).
  /// Same keys the push data map uses, so taps route identically.
  static String? orderIdFrom(Map<String, dynamic> order) {
    final id = (order['orderMongoId'] ?? order['_id'] ?? order['orderId'])
        ?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Rings for an order delivered over the socket.
  ///
  /// Reuses [LocalNotificationService.show] with `isNewOrder: true` so it goes
  /// out on the `new_order_channel_v2` channel — max importance, `tujh_bin`
  /// sound, Accept/Reject actions — exactly as the push path does.
  /// `fullScreenIntent` stays false: the socket only delivers while the app is
  /// running, and a full-screen takeover there races the in-app dialog.
  static Future<void> ringForSocketOrder(Map<String, dynamic> order) async {
    final orderId = orderIdFrom(order);
    if (!claim(orderId)) return;

    await LocalNotificationService.instance.show(
      title: 'New order received',
      body: _body(order),
      payload: jsonEncode({'type': 'new_order', 'orderId': orderId}),
      isNewOrder: true,
      fullScreenIntent: false,
    );
  }

  static String _body(Map<String, dynamic> order) {
    final ref = (order['order_id'] ?? order['orderId'])?.toString();
    final total = order['total'];
    final parts = <String>[
      if (ref != null && ref.isNotEmpty) 'Order #$ref',
      if (total is num) 'Total: Rs.${total.toStringAsFixed(0)}',
    ];
    return parts.isEmpty ? 'Tap to review the order.' : parts.join('  ·  ');
  }
}
