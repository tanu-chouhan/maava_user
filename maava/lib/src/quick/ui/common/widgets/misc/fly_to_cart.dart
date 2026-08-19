import 'package:flutter/material.dart';

import '../../../../../presentation/cart/animations/add_to_cart_animation.dart';

/// Key attached to the cart icon so the fly animation knows where to land.
final GlobalKey cartAnchorKey = GlobalKey(debugLabel: 'cart-anchor');

/// Animates a ghost of the product image from the tapped card to the cart icon.
///
/// This is a thin delegation to the food module's [AddToCartAnimation] so both
/// verticals fly the *same* animation — same trajectory, duration, curve and
/// centre-to-centre morph — rather than two lookalikes that drift apart.
///
/// Mart had its own copy, and it differed in the one way that mattered: it
/// inserted into `Overlay.maybeOf(context)`, the *nearest* overlay. Inside a
/// `StatefulShellRoute` branch that overlay lives inside the Scaffold body, so
/// the ghost painted underneath the bottom navigation bar and the flight was
/// hidden exactly where it was meant to land. The food implementation uses the
/// root overlay and documents why.
abstract final class FlyToCart {
  static void run(
    BuildContext context, {
    required GlobalKey sourceKey,
    required String imageUrl,
  }) {
    // No anchor means the cart icon is not on screen (e.g. a full-screen sheet
    // over the shell). Skipping is correct: there is nowhere to fly to, and the
    // cart count still updates from state.
    if (cartAnchorKey.currentContext == null) return;

    AddToCartAnimation.run(
      context: context,
      startKey: sourceKey,
      endKey: cartAnchorKey,
      imageUrl: imageUrl,
      // The badge is driven by cart state, not by this callback, so a rapid
      // series of adds each fly independently and none of them can desync the
      // count.
      onAnimationComplete: () {},
    );
  }
}
