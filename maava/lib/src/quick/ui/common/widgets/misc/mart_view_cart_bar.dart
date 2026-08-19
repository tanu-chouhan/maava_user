import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../presentation/cart/widgets/floating_view_cart_bar.dart';
import '../../../../di/app_providers.dart';
import '../../../../navigation/route_paths.dart';

/// Mart's "View Cart" bar.
///
/// Deliberately *not* a new widget: it feeds Mart's cart figures into the food
/// module's [FloatingViewCartBar], so both verticals show the identical bar —
/// same elastic slide-in, bump-on-add, glow sweep, thumbnail stack and
/// count-up. Only the numbers come from a different cart.
class MartViewCartBar extends ConsumerWidget {
  const MartViewCartBar({super.key, this.bottomOffset = 24.0});

  final double bottomOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider.select((s) => s.cart));

    return FloatingViewCartBar(
      // `go`, not `push`: push stacks the cart *over* the shell, leaving
      // currentIndex on Home, so the shell's "hide on the cart branch" guard
      // never fires and this bar floats on top of the cart it points at.
      onTap: () => context.go(RoutePaths.cart),
      bottomOffset: bottomOffset,
      // Distinct lines drive visibility and the "N items" label; total quantity
      // drives the bump so bumping an existing line still animates.
      itemCount: cart.lineCount,
      // Server-calculated total when /calculate has run, provisional subtotal
      // until then — never a client-invented figure.
      subtotal: cart.effectiveTotal,
      quantity: cart.itemCount,
      imageUrls: cart.items.map((i) => i.product.imageUrl).toList(),
    );
  }
}
