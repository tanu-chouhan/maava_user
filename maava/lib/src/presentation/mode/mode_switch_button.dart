import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../branding/theme_color_provider.dart';
import '../navigation/route_names.dart';
import 'app_mode.dart';

/// The raised disc in the middle of the bottom bar that flips the app between
/// the food and quick-commerce modules.
///
/// It shows the **destination**, never the current mode: in Food it reads
/// "Quick" in quick's teal, in Quick it reads "Food" in the food violet. A
/// control that showed the current mode would look like a status light and
/// invite the "why is nothing happening" tap.
///
/// State comes from [appModeProvider] — the same source the header switcher
/// and the shared-screen theming read — so the two controls cannot disagree.
class ModeSwitchButton extends ConsumerStatefulWidget {
  const ModeSwitchButton({super.key, this.diameter = 56});

  final double diameter;

  @override
  ConsumerState<ModeSwitchButton> createState() => _ModeSwitchButtonState();
}

class _ModeSwitchButtonState extends ConsumerState<ModeSwitchButton>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 320);

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.08,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _switch(AppMode destination) async {
    // Press-in, then release — the scale settles while the route is already
    // changing, so the gesture reads as one motion rather than two steps.
    await _press.forward();
    if (!mounted) return;
    unawaited(_press.reverse());

    ref.read(appModeProvider.notifier).set(destination);
    if (!mounted) return;
    // `go`, not `push`: switching module replaces the stack rather than piling
    // the other vertical's home on top of this one.
    //
    // Entering Mart plays the HiberMart opener first; it forwards to the Mart
    // home itself once the animation finishes. Mode is already set above, so
    // the opener and everything after it are teal.
    context.go(
      destination == AppMode.quick
          ? RouteNames.martSplash
          : homePathFor(destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    // One global palette now, so both sections share this colour: the icon and
    // label carry the destination, not the hue.
    final palette = ref.watch(themeColorProvider);
    final destination = mode == AppMode.food ? AppMode.quick : AppMode.food;

    final (color, icon, label) = destination == AppMode.quick
        ? (palette.color, Icons.shopping_basket_rounded, 'Mart')
        : (palette.color, Icons.restaurant_rounded, 'Food');

    return Semantics(
      button: true,
      label: 'Switch to $label',
      child: GestureDetector(
        onTap: () => _switch(destination),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.diameter + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lifted so the disc floats proud of the bar. Nothing clips here,
              // which is what lets it overlap the bar's top edge.
              Transform.translate(
                offset: const Offset(0, -14),
                child: AnimatedBuilder(
                  animation: _press,
                  builder: (context, child) => Transform.scale(
                    scale: 1 - _press.value,
                    child: child,
                  ),
                  child: AnimatedContainer(
                    duration: _duration,
                    curve: Curves.easeOutCubic,
                    width: widget.diameter,
                    height: widget.diameter,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: _duration,
                      switchInCurve: Curves.easeOutBack,
                      // Rotate + fade, so the icon turns over into the new one
                      // rather than popping.
                      transitionBuilder: (child, animation) => RotationTransition(
                        turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        icon,
                        key: ValueKey(icon.codePoint),
                        color: Colors.white,
                        size: widget.diameter * 0.44,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: AnimatedDefaultTextStyle(
                  duration: _duration,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local `unawaited` so the reverse animation is explicitly fire-and-forget.
void unawaited(Future<void> _) {}
