import 'package:flutter_test/flutter_test.dart';
import 'package:maava_delivery/features/profile/application/service_type_controller.dart';

void main() {
  test('two toggles map onto the four serviceType values', () {
    expect(foodReceives('both'), isTrue);
    expect(martReceives('both'), isTrue);
    expect(foodReceives('food'), isTrue);
    expect(martReceives('food'), isFalse);
    expect(foodReceives('quick'), isFalse);
    expect(martReceives('quick'), isTrue);
    expect(foodReceives('none'), isFalse);
    expect(martReceives('none'), isFalse);
  });

  test('incoming orders are gated by the toggles', () {
    expect(serviceTypeAllows('both', 'food'), isTrue);
    expect(serviceTypeAllows('both', 'quick'), isTrue);
    expect(serviceTypeAllows('food', 'quick'), isFalse);
    expect(serviceTypeAllows('quick', 'food'), isFalse);
    expect(serviceTypeAllows('none', 'food'), isFalse);
    expect(serviceTypeAllows('none', 'quick'), isFalse);
    // Legacy payloads without a vertical pass unless everything is off.
    expect(serviceTypeAllows('both', null), isTrue);
    expect(serviceTypeAllows('none', null), isFalse);
  });
}
