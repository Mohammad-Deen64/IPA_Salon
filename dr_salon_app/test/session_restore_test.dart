import 'dart:convert';

import 'package:dr_salon_app/services/session_store.dart';
import 'package:dr_salon_app/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_salon_app/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SessionStore.resetForTest();
    await SessionStore.clear();
  });

  tearDown(() async {
    await SessionStore.clear();
    SessionStore.resetForTest();
  });

  test('persist never stores a password and keeps the chosen role', () async {
    final state = AppState(location: _SilentLocation());
    state.chooseRole(UserRole.owner);
    await state.toggleTheme();
    final saved = await SessionStore.read();
    expect(saved['role'], 'owner');
    expect(saved.containsKey('password'), isFalse);
    expect(jsonEncode(saved).toLowerCase().contains('password'), isFalse);
  });

  test('choosing customer stores the customer role locally', () async {
    final state = AppState(location: _SilentLocation());
    state.chooseRole(UserRole.customer);
    await state.toggleTheme();
    final saved = await SessionStore.read();
    expect(saved['role'], 'customer');
  });
}

class _SilentLocation extends LocationService {
  @override
  Future<UserLocation> current() async {
    return const UserLocation(
      latitude: 33.6844,
      longitude: 73.0479,
      usedGps: false,
      message: 'Using default location.',
    );
  }
}
