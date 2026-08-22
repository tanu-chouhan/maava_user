import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_impl/api_paths.dart';
import 'app_providers.dart';
import 'repository_providers.dart';

/// The delivery zone serving the user's selected address.
///
/// Mart is zone-scoped: a store belongs to a zone, and a shopper must only ever
/// see stock from stores that serve where they are. The zone is resolved from
/// the address's own coordinates by the backend's polygon test, so the app
/// never decides which zone a point falls in — it only reports the point.
///
/// Null means "not known yet": no address selected, no coordinates on it, or
/// the lookup failed. Callers send no zone in that case, which the backend
/// reads as unfiltered rather than empty — a shopper who has not set an address
/// still sees a catalogue instead of a blank app.
final martZoneProvider = FutureProvider<String?>((ref) async {
  final address = ref.watch(selectedAddressProvider);
  var lat = address?.latitude;
  var lng = address?.longitude;

  // No saved address: ask the device where it is.
  //
  // Falling straight through to "no zone" meant an unfiltered catalogue — every
  // store in every city at once — so a shopper could put two items in the cart
  // that no single store could deliver, and the cart asked them to start over.
  // A signed-out shopper standing in Indore should see Indore's store.
  if (lat == null || lng == null) {
    try {
      final here = await ref.read(locationServiceProvider).currentLocation();
      lat = here.latitude;
      lng = here.longitude;
    } catch (_) {
      // Permission refused or location off: fall through to no zone rather
      // than blocking the catalogue behind a permission prompt.
      return null;
    }
  }

  try {
    final json = await ref
        .watch(apiClientProvider)
        .get(ApiPaths.zoneDetect, query: {'lat': lat, 'lng': lng});
    if (json is! Map<String, dynamic>) return null;
    final zoneId = json['zoneId']?.toString().trim() ?? '';
    return zoneId.isEmpty ? null : zoneId;
  } catch (_) {
    // A failed lookup must not empty the catalogue.
    return null;
  }
});

/// Synchronous view of [martZoneProvider] for the repositories, which build a
/// query string rather than awaiting.
final martZoneIdProvider = Provider<String?>(
  (ref) => ref.watch(martZoneProvider).value,
);
