import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maava/src/presentation/home/viewmodels/zone_viewmodel.dart';

/// Food listings must not be scoped by the detected zone.
///
/// Food restaurants carry no zoneId, so once Mart zones existed and detection
/// started returning a real id, every food listing collapsed: 25 restaurants
/// to 2, 111 dishes to 6, and the 99 Store's cuisine chips to nothing.
void main() {
  test('the food catalogue is unscoped', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(catalogZoneIdProvider), isNull);
  });
}
