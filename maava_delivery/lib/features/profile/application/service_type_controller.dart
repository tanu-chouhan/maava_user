import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../data/profile_repository.dart';

/// Which order types this rider receives: 'food' | 'quick' | 'both' | 'none'.
///
/// One value, two switches — the profile card renders it as independent
/// Food/Mart toggles. The backend's dispatch filter (`serviceType` on the
/// partner) is the enforcement point; this mirrors the choice locally so the
/// switches survive a restart even when the profile fetch hasn't landed yet.
/// The local copy wins over the server default: a backend that predates the
/// field echoes nothing back, and adopting that would silently flip both
/// toggles on again.
class ServiceTypeController extends Notifier<String> {
  static const _prefsKey = 'rider.serviceType';

  @override
  String build() {
    unawaited(_load());
    return 'both';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
      return;
    }
    // Fresh install: fall back to the choice made at registration, which the
    // server carries on the profile.
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) state = auth.user.serviceType;
  }

  Future<void> setFood(bool on) =>
      _apply(food: on, mart: martReceives(state));

  Future<void> setMart(bool on) =>
      _apply(food: foodReceives(state), mart: on);

  Future<void> _apply({required bool food, required bool mart}) async {
    final value = food && mart
        ? 'both'
        : food
            ? 'food'
            : mart
                ? 'quick'
                : 'none';
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value);
    // Server-side enforcement: dispatch and the available-orders list filter
    // on this field, so the toggle works even when the app is killed.
    unawaited(
      ref.read(profileRepositoryProvider).updateProfile({'serviceType': value}),
    );
  }
}

/// True when [serviceType] includes Maava Food orders.
bool foodReceives(String serviceType) =>
    serviceType == 'both' || serviceType == 'food';

/// True when [serviceType] includes HiberMart orders.
bool martReceives(String serviceType) =>
    serviceType == 'both' || serviceType == 'quick';

/// Whether an incoming order of [vertical] passes the rider's toggles.
/// Unknown verticals (legacy payloads) pass unless everything is off.
bool serviceTypeAllows(String serviceType, String? vertical) =>
    switch (vertical) {
      'food' => foodReceives(serviceType),
      'quick' => martReceives(serviceType),
      _ => serviceType != 'none',
    };

final serviceTypeControllerProvider =
    NotifierProvider<ServiceTypeController, String>(ServiceTypeController.new);
