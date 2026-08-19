import 'package:flutter/material.dart';

import '../branding/app_colors.dart';
import 'splash_screen.dart' show PerfectAmoebaClipper, VideoStyleDotLoader;

/// The HiberMart opener, shown each time the user switches into Mart.
///
/// Deliberately the *same* animation as the app's launch splash — same amoeba
/// clipper, same interval curves, same dot loader — so entering Mart reads as
/// the app opening a section rather than a screen transition.
class MartSplashScreen extends StatefulWidget {
  const MartSplashScreen({super.key, required this.onFinished});

  /// Called once the animation completes; the caller decides where to land.
  final VoidCallback onFinished;

  @override
  State<MartSplashScreen> createState() => _MartSplashScreenState();
}

class _MartSplashScreenState extends State<MartSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _blobScale;
  late final Animation<double> _screenSpread;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _blobScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutBack),
      ),
    );
    _screenSpread = Tween<double>(begin: 1.0, end: 16.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeInOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.48, curve: Curves.easeIn),
      ),
    );
    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) widget.onFinished();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Amoeba Blob Animation with Main Maava Splash Brand Primary Color
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _blobScale.value * _screenSpread.value,
              child: ClipPath(
                clipper: PerfectAmoebaClipper(),
                child: Container(
                  width: 480,
                  height: 480,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // 2. Exact Maava Logo Image
          AnimatedBuilder(
            animation: _logoOpacity,
            builder: (context, child) => Opacity(
              opacity: _logoOpacity.value,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 270,
                      height: 270,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Dot Loader
          Positioned(
            bottom: 65,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _loaderOpacity,
                builder: (context, child) =>
                    Opacity(opacity: _loaderOpacity.value, child: child),
                child: const VideoStyleDotLoader(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
