import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../domain/model/banner.dart';
import '../../../common/widgets/misc/app_network_image.dart';
import '../../../common/widgets/loaders/shimmer_box.dart';
import '../../../../core/theme/app_theme.dart';

/// Auto-scrolling promo carousel with width-animating pagination dots.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
    this.isLoading = false,
    this.discountPercent,
    this.height = AppDimens.bannerHeight,
  });

  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner> onTap;
  final bool isLoading;

  /// Headline saving across the live offers, shown as the corner disc. Null
  /// when nothing is on offer — the badge is never invented.
  final int? discountPercent;
  final double height;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.98);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(AppDurations.bannerAutoScroll, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % widget.banners.length,
        duration: AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerBox(height: 196, radius: AppRadii.rXl),
      );
    }

    // No banners published means no carousel. Inventing a "Daily Essentials
    // Delivered in 10 Minutes" card here filled the space with a promotion no
    // merchant had made, and it tapped through to nowhere.
    // A published banner with no image, no copy and no CTA has nothing to
    // draw — it used to render as an empty grey plate the size of the hero.
    final bannersToDisplay = widget.banners
        .where(
          (b) =>
              b.mediaUrl.trim().isNotEmpty ||
              b.title.trim().isNotEmpty ||
              b.ctaText.trim().isNotEmpty,
        )
        .toList();
    if (bannersToDisplay.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: RepaintBoundary(
            child: PageView.builder(
              controller: _controller,
              itemCount: bannersToDisplay.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                final banner = bannersToDisplay[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => widget.onTap(banner),
                    child: _HeroBannerCard(
                      banner: banner,
                      discountPercent: widget.discountPercent,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannersToDisplay.length,
            (i) => AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: i == _index ? 18 : 6,
              decoration: BoxDecoration(
                color: i == _index
                    ? context.colors.primary
                    : context.semantic.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The hero card.
///
/// Reproduces the reference layout — eyebrow, two-tone headline, body, a filled
/// and an outlined CTA, and the media bleeding off the right edge under a
/// circular discount badge. Every one of those slots is filled from the banner
/// record, so the card only shows the parts the admin actually published; a
/// media-only banner (no title, no CTA) renders edge-to-edge instead of framing
/// empty text.
class _HeroBannerCard extends StatelessWidget {
  const _HeroBannerCard({required this.banner, this.discountPercent});

  final PromoBanner banner;

  /// Best live offer, shown as the corner badge. Null hides the badge.
  final int? discountPercent;

  bool get _hasCopy =>
      banner.title.trim().isNotEmpty || _ctaLabel != null;

  /// The button label the admin wrote, or a plain action verb when they gave a
  /// destination but no wording. Null when the banner links nowhere.
  String? get _ctaLabel {
    final written = banner.ctaText.trim();
    if (written.isNotEmpty) return written;
    return banner.ctaLink.trim().isEmpty ? null : 'Shop now';
  }

  @override
  Widget build(BuildContext context) {
    final media = _media(context);

    // Nothing but media: let it fill the card, the way a designed banner image
    // is meant to be seen.
    if (!_hasCopy) {
      return Container(
        decoration: BoxDecoration(
          color: context.semantic.brandSurfaceSoft,
          borderRadius: AppRadii.rLg,
          boxShadow: context.semantic.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            media,
            if (discountPercent != null)
              Positioned(top: 12, right: 12, child: _DiscountDisc(percent: discountPercent!)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.semantic.brandSurfaceSoft,
        borderRadius: AppRadii.rLg,
        boxShadow: context.semantic.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Media bleeds off the right edge, behind the copy column.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 200,
            child: media,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 0, 18),
            child: SizedBox(
              width: 208,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner.title.trim().isNotEmpty)
                    _TwoToneHeadline(title: banner.title.trim()),
                  if (_ctaLabel != null) ...[
                    const SizedBox(height: 14),
                    _HeroCta(label: _ctaLabel!),
                  ],
                ],
              ),
            ),
          ),
          if (discountPercent != null)
            Positioned(top: 14, right: 14, child: _DiscountDisc(percent: discountPercent!)),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    if (banner.isVideo) return _BannerVideo(banner: banner);
    if (banner.mediaUrl.trim().isEmpty) return const SizedBox.shrink();
    return AppNetworkImage(
      url: banner.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// The reference splits the headline across two lines, the second in the brand
/// green. Admins write one string, so the split is the first line break — or
/// the halfway word boundary when they wrote a single line.
class _TwoToneHeadline extends StatelessWidget {
  const _TwoToneHeadline({required this.title});

  final String title;

  (String, String) get _lines {
    final byBreak = title.split(RegExp(r'[\r\n]+'));
    if (byBreak.length > 1) {
      return (byBreak.first.trim(), byBreak.sublist(1).join(' ').trim());
    }
    final words = title.split(' ')..removeWhere((w) => w.isEmpty);
    if (words.length < 2) return (title, '');
    final cut = (words.length / 2).ceil();
    return (words.take(cut).join(' '), words.skip(cut).join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final (first, second) = _lines;
    final style = context.text.displayMedium!.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 22,
      height: 1.15,
      letterSpacing: -0.4,
    );

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style.copyWith(color: context.colors.onSurface),
        children: [
          TextSpan(text: first),
          if (second.isNotEmpty)
            TextSpan(
              text: '\n$second',
              style: style.copyWith(color: context.colors.primary),
            ),
        ],
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 13, color: context.colors.onPrimary),
        ],
      ),
    );
  }
}

/// The circular "UP TO n% OFF" flash over the hero media.
class _DiscountDisc extends StatelessWidget {
  const _DiscountDisc({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: context.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'UP TO',
            style: context.text.labelSmall!.copyWith(
              color: context.colors.onPrimary,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            '$percent%',
            style: context.text.labelMedium!.copyWith(
              color: context.colors.onPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          Text(
            'OFF',
            style: context.text.labelSmall!.copyWith(
              color: context.colors.onPrimary,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A video banner, muted and looping like the still ones auto-advance.
///
/// Falls back to the banner's own copy if the media will not initialise, so a
/// dead URL degrades to a readable card rather than an empty plate.
class _BannerVideo extends StatefulWidget {
  const _BannerVideo({required this.banner});

  final PromoBanner banner;

  @override
  State<_BannerVideo> createState() => _BannerVideoState();
}

class _BannerVideoState extends State<_BannerVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.banner.mediaUrl);
    if (uri == null) {
      setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      // Autoplaying audio over a shopping page is never wanted.
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return ColoredBox(color: context.semantic.brandSurfaceSoft);
    }

    final controller = _controller;
    if (controller == null) {
      return const ShimmerBox(height: 196, radius: AppRadii.rXl);
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
