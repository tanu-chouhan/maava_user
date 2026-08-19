import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../quick/core/theme/quick_theme_scope.dart';
import '../../../quick/ui/screens/order/orders_list/orders_screen.dart' as quick;
import '../../../shared/orders/global_orders.dart';
import '../../branding/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'orders_screen.dart';

/// The one MAAVA order history.
///
/// "All" merges both verticals into a single stream; the Food and Quick tabs
/// keep each vertical's own list, which is where the domain-specific detail
/// (dish ratings vs stock and packs) lives. Every row opens the details screen
/// belonging to its own vertical.
class UnifiedOrdersScreen extends ConsumerStatefulWidget {
  const UnifiedOrdersScreen({super.key});

  @override
  ConsumerState<UnifiedOrdersScreen> createState() =>
      _UnifiedOrdersScreenState();
}

class _UnifiedOrdersScreenState extends ConsumerState<UnifiedOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(icon: Icon(Icons.restaurant_rounded, size: 20), text: 'Food'),
            Tab(
              icon: Icon(Icons.shopping_basket_rounded, size: 20),
              text: 'Mart',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _AllOrdersList(),
          const OrdersScreen(showAppBar: false),
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: const QuickThemeScope(
              child: quick.OrdersScreen(showAppBar: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllOrdersList extends ConsumerWidget {
  const _AllOrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Guests have no orders in either vertical, and neither list fetches for
    // them — so ask for sign-in rather than showing a spinner that never
    // resolves (the food view model reports isLoading until its first fetch,
    // which for a guest never happens).
    final isSignedIn = ref.watch(authViewModelProvider).value != null;
    if (!isSignedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Sign in to see your orders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your food and quick-commerce orders appear here together.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/login?from=/orders'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = ref.watch(globalOrdersProvider);
    final isLoading = ref.watch(globalOrdersLoadingProvider);

    if (orders.isEmpty) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No orders yet.\nYour food and quick-commerce orders will appear here together.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _GlobalOrderCard(order: orders[i]),
    );
  }
}

class _GlobalOrderCard extends StatelessWidget {
  const _GlobalOrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Food follows the app's brand colour; quick keeps its own green so the two
    // verticals stay tellable apart at a glance in the merged list.
    final accent = order.isFood ? AppColors.primary : const Color(0xFF0E7C66);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.12),
          foregroundColor: accent,
          child: Icon(
            order.isFood
                ? Icons.restaurant_rounded
                : Icons.shopping_basket_rounded,
            size: 20,
          ),
        ),
        title: Text(
          order.storeName.isEmpty ? 'MAAVA order' : order.storeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.isFood ? 'FOOD' : 'QUICK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    order.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ₹${order.total.toStringAsFixed(0)}'
              '${order.displayId.isEmpty ? '' : ' · ${order.displayId}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(order.detailsRoute),
      ),
    );
  }
}
