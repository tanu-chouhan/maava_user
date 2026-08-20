import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maava_mart_seller/config/theme/app_palette.dart';
import 'package:maava_mart_seller/features/orders/domain/order_model.dart';
import 'package:maava_mart_seller/features/orders/presentation/controllers/orders_controller.dart';
import 'package:maava_mart_seller/features/notifications/presentation/controllers/notifications_controller.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  /// Labels only. The counts beside them are derived from the orders on screen,
  /// because a pill that says 6 while the list shows none is worse than no
  /// number at all.
  static const List<String> _filterLabels = [
    'All Orders',
    'New',
    'Accepted',
    'Preparing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

  List<Map<String, dynamic>> _filtersFor(List<OrderModel> orders) {
    int count(OrderStatus s) => orders.where((o) => o.status == s).length;
    final byLabel = <String, int>{
      'All Orders': orders.length,
      'New': count(OrderStatus.newOrder),
      'Accepted': count(OrderStatus.preparing),
      'Preparing': count(OrderStatus.preparing),
      'Ready': count(OrderStatus.ready),
      'Completed': count(OrderStatus.delivered),
      'Cancelled': count(OrderStatus.cancelled),
    };
    return _filterLabels
        .map((l) => {'label': l, 'count': '${byLabel[l] ?? 0}'})
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: context.textPrimary,
              size: 26,
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'app',
                    style: TextStyle(color: context.textPrimary),
                  ),
                  TextSpan(
                    text: 'zeto',
                    style: TextStyle(color: Color(0xFF0F9D58)),
                  ),
                ],
              ),
            ),
            Text(
              'Quick Seller',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: context.textPrimary,
                  size: 26,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              // Hidden at zero: a badge reading "0" is worse than no badge.
              if (ref.watch(unreadNotificationsCountProvider) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${ref.watch(unreadNotificationsCountProvider)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header Title
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage and track all incoming orders',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 16),

              // Filter Pills Horizontal ListView
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (() {
                    final orders =
                        ref.watch(ordersControllerProvider).value ?? const [];
                    final filters = _filtersFor(orders);
                    return List.generate(filters.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      final f = filters[index];

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilterIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFEF3C7)
                                : context.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFC400)
                                  : context.borderColor,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                f['label'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f['count'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFFD97706)
                                      : context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  })(),
                ),
              ),
              const SizedBox(height: 14),

              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by order ID / customer / phone',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: context.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: context.textPrimary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: context.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Today
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...(() {
                final all =
                    ref.watch(ordersControllerProvider).value ?? const [];
                final now = DateTime.now();
                final today = all.where(
                  (o) =>
                      o.createdAt.year == now.year &&
                      o.createdAt.month == now.month &&
                      o.createdAt.day == now.day,
                );
                if (today.isEmpty) {
                  return [_buildEmptySection('No orders yet today')];
                }
                return today.map((o) => _buildOrderCard(_cardFor(o))).toList();
              })(),

              // Section: Yesterday — header included only when it has orders
              // under it. Rendering it unconditionally left a bare heading
              // floating over empty space on every account with no older
              // orders, which reads as content that failed to load.
              ...(() {
                final all =
                    ref.watch(ordersControllerProvider).value ?? const [];
                final now = DateTime.now();
                final earlier = all
                    .where(
                      (o) =>
                          !(o.createdAt.year == now.year &&
                              o.createdAt.month == now.month &&
                              o.createdAt.day == now.day),
                    )
                    .toList();
                if (earlier.isEmpty) return <Widget>[];

                return <Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Yesterday',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...earlier.map((o) => _buildOrderCard(_cardFor(o))),
                ];
              })(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown where cards would be when there is genuinely nothing to show. Uses
  /// the same card metrics as an order row so the list does not jump.
  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 30,
            color: context.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Shapes a real order into the map `_buildOrderCard` already renders, so the
  /// card keeps its exact layout and only its contents become true.
  Map<String, dynamic> _cardFor(OrderModel o) {
    final (label, bg, fg, action) = switch (o.status) {
      OrderStatus.newOrder => (
        'New',
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
        'Accept Order',
      ),
      OrderStatus.preparing => (
        'Preparing',
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        'Mark Ready',
      ),
      OrderStatus.ready => (
        'Ready',
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        'Handed Over',
      ),
      OrderStatus.delivered => (
        'Completed',
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        '',
      ),
      OrderStatus.cancelled => (
        'Cancelled',
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
        '',
      ),
    };

    final count = o.items.fold<int>(0, (n, i) => n + i.quantity);

    return {
      'id': o.orderNumber.isEmpty ? o.id : o.orderNumber,
      'orderId': o.id,
      'status': label,
      'statusColor': bg,
      'textColor': fg,
      'customer': o.customer.name,
      'phone': o.customer.phone,
      'amount': '₹${o.totalAmount.toStringAsFixed(2)}',
      'items': '$count item${count == 1 ? '' : 's'}',
      'distance': o.customer.address,
      'time': _formatWhen(o.createdAt),
      'action': action,
      'expiry': '',
    };
  }

  static String _formatWhen(DateTime at) {
    final h = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final m = at.minute.toString().padLeft(2, '0');
    final period = at.hour < 12 ? 'AM' : 'PM';
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return '${sameDay ? 'Today' : '${at.day}/${at.month}'}, $h:$m $period';
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final bool isOutlined = o['isOutlined'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap: long status labels ("Out for Delivery") must fall
                    // to a second line rather than overflow the card.
                    Wrap(
                      spacing: 2,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Order ID ',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: o['statusColor'] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o['status'].toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: o['textColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o['id'].toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            o['customer'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            o['phone'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      o['amount'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      o['items'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Button
                    if (isOutlined)
                      OutlinedButton(
                        onPressed: () => context.push('/order-details/${o['orderId']}'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          o['action'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => context.push('/order-details/${o['orderId']}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC400),
                          foregroundColor: const Color(0xFF181C2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          o['action'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ),

                    if (o['expiry'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        o['expiry'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                size: 14,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              const Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: Text(
                  '  •  ${o['distance']}  •  ${o['time']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
