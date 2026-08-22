import 'dart:async';

import 'package:flutter/material.dart';

/// The offer strip, cycling right-to-left through every offer the backend sent.
///
/// The strip used to render `offerBadges.first` and nothing else, so a
/// restaurant with four offers advertised one and silently dropped the rest.
///
/// Each offer holds for [_dwell] then slides away over [_slide] on an
/// ease-in-out curve. Paging is unbounded in both directions — the item builder
/// wraps with a modulo — so the last offer runs into the first with no jump
/// back through the list and no blank page at either end.
///
/// A manual swipe wins: the timer stops while the finger is down and only
/// restarts [_resumeAfter] later, so the carousel never fights the user or
/// yanks the page out from under them mid-read.
class AutoScrollingOffers extends StatefulWidget {
  const AutoScrollingOffers({
    super.key,
    required this.offers,
    required this.itemBuilder,
    required this.height,
  });

  /// Offer lines, in the order the backend returned them.
  final List<String> offers;

  final Widget Function(BuildContext context, String offer) itemBuilder;

  /// Fixed so the surrounding card never changes height as offers rotate.
  final double height;

  static const _dwell = Duration(milliseconds: 3500);
  static const _slide = Duration(milliseconds: 600);
  static const _resumeAfter = Duration(seconds: 5);

  /// Far from zero so the strip can be swiped backwards from the start without
  /// hitting the beginning of the list.
  static const _initialPage = 10000;

  @override
  State<AutoScrollingOffers> createState() => _AutoScrollingOffersState();
}

class _AutoScrollingOffersState extends State<AutoScrollingOffers> {
  late final PageController _controller;
  Timer? _advance;
  Timer? _resume;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.offers.isNotEmpty
        ? AutoScrollingOffers._initialPage -
            (AutoScrollingOffers._initialPage % widget.offers.length)
        : AutoScrollingOffers._initialPage;
    _controller = PageController(initialPage: initialPage);
    _startAdvancing();
  }

  @override
  void didUpdateWidget(AutoScrollingOffers old) {
    super.didUpdateWidget(old);
    // The admin can add or remove offers; restart advancing if list changes.
    if (old.offers.length != widget.offers.length) _startAdvancing();
  }

  void _startAdvancing() {
    _advance?.cancel();
    if (widget.offers.length < 2) return;
    _advance = Timer.periodic(AutoScrollingOffers._dwell, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: AutoScrollingOffers._slide,
        curve: Curves.easeInOut,
      );
    });
  }

  /// Hands control back to the user, then resumes once they have stopped.
  void _pauseForInteraction() {
    _advance?.cancel();
    _resume?.cancel();
    _resume = Timer(AutoScrollingOffers._resumeAfter, () {
      if (mounted) _startAdvancing();
    });
  }

  @override
  void dispose() {
    _advance?.cancel();
    _resume?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();
    if (widget.offers.length == 1) {
      return SizedBox(
        height: widget.height,
        child: widget.itemBuilder(context, widget.offers.first),
      );
    }

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Only a real drag pauses it; the timer's own animation must not.
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _pauseForInteraction();
          }
          if (notification is ScrollEndNotification &&
              _advance?.isActive != true) {
            _pauseForInteraction();
          }
          return false;
        },
        child: PageView.builder(
          controller: _controller,
          itemBuilder: (context, index) => widget.itemBuilder(
            context,
            widget.offers[index % widget.offers.length],
          ),
        ),
      ),
    );
  }
}
