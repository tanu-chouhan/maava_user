import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maava_mart_seller/core/logging/startup_log.dart';
import 'package:maava_mart_seller/core/providers/onboarding_provider.dart';
import 'package:maava_mart_seller/features/auth/presentation/controllers/auth_controller.dart';
import 'package:maava_mart_seller/core/providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _watchdogTimeout = Duration(seconds: 15);
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH] Splash screen opened');
    startupLog('splash.initState');

    _watchdog = Timer(_watchdogTimeout, () {
      if (!mounted) return;
      startupLog('splash.WATCHDOG FIRED — startup never completed');
      ref.read(authControllerProvider.notifier).forceLoggedOut();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    debugPrint('[SPLASH] Initialization started');
    startupLog('splash.bootstrap start');
    final startTime = DateTime.now();

    try {
      if (!mounted) return;
      ref.read(hasSeenOnboardingProvider.notifier).set(true);

      await ref.read(authControllerProvider.notifier).resolveSession();
      debugPrint('[SPLASH] Initialization completed');
    } catch (e, stack) {
      startupLog('splash.bootstrap FAILED', e);
      if (kDebugMode) debugPrint('$stack');
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).forceLoggedOut();
      debugPrint('[SPLASH] Initialization completed (fallback logged out)');
    } finally {
      // Enforce minimum splash screen display time of 2 seconds (2000ms)
      const minDisplayDuration = Duration(milliseconds: 2000);
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minDisplayDuration) {
        await Future.delayed(minDisplayDuration - elapsed);
      }
      debugPrint(
        '[SPLASH] Minimum delay completed (${DateTime.now().difference(startTime).inMilliseconds}ms)',
      );

      _watchdog?.cancel();
      startupLog(
        'splash.bootstrap end',
        ref.read(authControllerProvider).runtimeType,
      );

      debugPrint('[SPLASH] Navigation started');
      if (mounted) {
        ref.read(splashCompletedProvider.notifier).markCompleted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFFC400);

    return Scaffold(
      backgroundColor: brandYellow,
      body: Center(
        child: _buildLogoHeader(),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shopping Bag with Motion Lines
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Motion lines
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // White Bag with 'a' logo inside
            Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bag Handle Arch
                  Positioned(
                    top: 6,
                    child: Container(
                      width: 20,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFC400),
                          width: 3,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // 'a' Letter inside bag
                  const Positioned(
                    bottom: 8,
                    child: Text(
                      'a',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFC400),
                        height: 1.0,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Brand Name Text: "appzeto"
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(
                text: 'app',
                style: TextStyle(color: Color(0xFF181C2E)),
              ),
              TextSpan(
                text: 'zeto',
                style: TextStyle(color: Color(0xFF0F9D58)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // "Quick Seller" Subtitle
        const Text(
          'Quick Seller',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181C2E),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
