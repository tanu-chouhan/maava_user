import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maava/src/data/datasources/address_remote_datasource.dart';
import 'package:maava/src/data/models/address_model.dart';
import 'package:maava/src/di/address_providers.dart';
import 'package:maava/src/presentation/address/viewmodels/address_viewmodel.dart';
import 'package:maava/src/quick/core/local_storage/local_storage.dart';
import 'package:maava/src/quick/di/repository_providers.dart'
    show localStorageProvider;
import 'package:maava/src/shared/address/global_address.dart';

AddressModel _addr(String id, String street, {String label = 'Home'}) =>
    AddressModel(
      id: id,
      title: label,
      fullAddress: '$street, Indore, MP, 452001',
      type: label,
      isDefault: false,
      street: street,
      city: 'Indore',
      state: 'MP',
      zipCode: '452001',
      latitude: 22.7,
      longitude: 75.8,
    );

/// Mirrors the backend's one-address-per-label rule: posting a second "Home"
/// UPDATES the existing row and returns it with its ORIGINAL id.
class _LabelDedupingRemote implements AddressRemoteDataSource {
  final Map<String, AddressModel> byLabel = {};
  int _seq = 0;

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    final existing = byLabel[address.type];
    final saved = existing == null
        ? _addr('id-${_seq++}', address.street, label: address.type)
        : _addr(existing.id, address.street, label: address.type);
    byLabel[address.type] = saved;
    return saved;
  }

  @override
  Future<List<AddressModel>> getAddresses() async => byLabel.values.toList();

  @override
  Future<AddressModel> updateAddress(AddressModel address) async => address;

  @override
  Future<void> deleteAddress(String id) async {}

  @override
  Future<AddressModel> setDefault(String id) async => byLabel.values.first;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryStorage implements LocalStorage {
  final Map<String, Object> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Any other storage call is irrelevant to this test.
    final name = invocation.memberName.toString();
    if (name.contains('get')) return null;
    return Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});

  test(
      'home shows the LATEST saved address when the backend dedupes by label '
      '(regression: stale first copy shadowed the update)', () async {
    final container = ProviderContainer(overrides: [
      addressRemoteDataSourceProvider.overrideWithValue(_LabelDedupingRemote()),
      localStorageProvider.overrideWithValue(_MemoryStorage()),
    ]);
    addTearDown(container.dispose);

    final vm = container.read(addressViewModelProvider.notifier);

    // Save "Home" once, select it — home header shows it.
    await vm.addAddress(_addr('', '12 MG Road'));
    var saved = container.read(addressViewModelProvider).last;
    container.read(selectedAddressIdProvider.notifier).select(saved.id);
    expect(container.read(globalSelectedAddressProvider)!.street, '12 MG Road');

    // Change it: save "Home" again with a different street. The backend
    // updates the same row (same id); the list must not keep a stale copy.
    await vm.addAddress(_addr('', '45 Rani Bagh'));
    expect(
      container.read(addressViewModelProvider).length,
      1,
      reason: 'same-id rows must merge, not stack',
    );
    expect(
      container.read(globalSelectedAddressProvider)!.street,
      '45 Rani Bagh',
      reason: 'the header must show the latest save immediately',
    );

    // And again — repeatedly changing keeps working.
    await vm.addAddress(_addr('', '7 Palasia Square'));
    expect(
      container.read(globalSelectedAddressProvider)!.street,
      '7 Palasia Square',
    );

    // A different label is a genuinely new row.
    await vm.addAddress(_addr('', '3 Office Park', label: 'Office'));
    expect(container.read(addressViewModelProvider).length, 2);
  });
}
