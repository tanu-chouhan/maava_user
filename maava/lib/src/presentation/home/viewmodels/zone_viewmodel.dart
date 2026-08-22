import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/zone_model.dart';
import '../../../di/catalog_providers.dart';

/// Detects the serviceable zone for the user's location.
///
/// Zone gates the home screen: `zoneId` is passed to every listing and search
/// call so results are scoped to the area we actually deliver to. When location
/// is unavailable or the point is out of coverage, we fall back to unscoped
/// (national) listings rather than showing an empty app.
final zoneViewModelProvider =
    AsyncNotifierProvider<ZoneViewModel, ZoneModel>(ZoneViewModel.new);

class ZoneViewModel extends AsyncNotifier<ZoneModel> {
  @override
  FutureOr<ZoneModel> build() => _detect();

  Future<ZoneModel> _detect() async {
    final position = await _currentPosition();
    if (position == null) return ZoneModel.unknown;

    final repo = ref.read(catalogRemoteDataSourceProvider);
    try {
      return await repo.detectZone(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // Zone detection must never hard-fail the app — unscoped listings are a
      // usable fallback.
      return ZoneModel.unknown;
    }
  }

  Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _detect());
  }
}

/// The zone id to scope catalog calls with, or null when undetected.
final currentZoneIdProvider = Provider<String?>((ref) {
  return ref.watch(zoneViewModelProvider).value?.zoneId;
});

/// Zone id for FOOD CATALOGUE listings — deliberately null.
///
/// Food restaurants carry no zoneId, so scoping listings by the detected zone
/// empties the section: with the Indore zone the catalogue drops from 25
/// restaurants to 2 and from 111 dishes to 6, and the 99 Store's Idli chip to
/// none at all. This went unnoticed until Mart zones were created — before
/// that, detection found no zone and every call was already unscoped.
///
/// Zone filtering is live for Mart only. Point this back at
/// [currentZoneIdProvider] once food restaurants are assigned zones. Checkout
/// keeps using the real zone, which is about delivery fees, not the catalogue.
final catalogZoneIdProvider = Provider<String?>((ref) => null);
