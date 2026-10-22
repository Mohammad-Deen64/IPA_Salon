import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/appointment.dart';
import '../models/chat.dart';
import '../models/salon.dart';
import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/booking_hours.dart';
import '../services/location_service.dart';
import '../services/salon_service.dart';
import '../services/session_store.dart';

enum UserRole { customer, owner }

class AppState extends ChangeNotifier {
  AppState({SalonServiceApi? api, AuthService? auth, LocationService? location})
      : _api = api ?? SalonServiceApi(),
        _auth = auth ?? AuthService(),
        _location = location ?? LocationService() {
    _auth.onUnauthorized = _handleUnauthorized;
    _api.onUnauthorized = _handleUnauthorized;
  }

  final SalonServiceApi _api;
  final AuthService _auth;
  final LocationService _location;
  bool _clearingSession = false;
  bool _restoring = false;

  AppUser? user;
  String? token;
  AppUser? _sessionUser;
  String? _sessionToken;
  UserRole? role;
  bool darkMode = true;
  bool loading = false;
  String? error;
  String? locationMessage;
  bool locationEnabled = false;
  double? userLatitude;
  double? userLongitude;
  int customerTab = 0;
  int chatCount = 0;
  List<Salon> salons = [];
  List<Appointment> appointments = [];
  List<String> savedSalonIds = [];
  List<String> hiddenBookingIds = [];
  String profileLocation = 'Islamabad, Pakistan';
  bool notificationsEnabled = true;
  String? avatarPath;

  List<Appointment> get visibleAppointments =>
      appointments.where((item) => !hiddenBookingIds.contains(item.id)).toList();
  Salon? selectedSalon;
  OwnerStats? stats;
  Salon? ownerProfile;
  List<SalonService> ownerServices = [];

  bool get isSignedIn => user != null && token != null;
  String get customerName => user?.name ?? '';
  String get customerPhone => user?.phone ?? '';
  String get customerEmail => user?.email ?? '';

  void openCustomerTab(int index) {
    customerTab = index;
    notifyListeners();
  }

  void chooseRole(UserRole next) {
    role = next;
    customerTab = 0;
    _applySessionForRole();
    notifyListeners();
    unawaited(_persist());
    if (next == UserRole.customer) {
      unawaited(loadCustomer());
    } else if (isSignedIn) {
      unawaited(loadOwner());
    }
  }

  Future<void> restoreLocal() async {
    _restoring = true;
    String? savedRoleName;
    try {
      final saved = await SessionStore.read();
      saved.remove('password');
      saved.remove('currentPassword');
      saved.remove('newPassword');
      darkMode = saved['darkMode'] as bool? ?? true;
      _sessionToken = saved['token'] as String?;
      final rawUser = saved['user'];
      if (rawUser is Map<String, dynamic>) {
        _sessionUser = AppUser.fromJson(rawUser);
      } else if (rawUser is Map) {
        _sessionUser = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      }
      savedRoleName = saved['role'] as String? ?? _sessionUser?.role;
      profileLocation = saved['profileLocation'] as String? ?? profileLocation;
      notificationsEnabled = saved['notificationsEnabled'] as bool? ?? true;
      avatarPath = saved['avatarPath'] as String?;
      final savedIds = saved['savedSalonIds'];
      if (savedIds is List) {
        savedSalonIds = savedIds.map((item) => item.toString()).toList();
      }
      final hidden = saved['hiddenBookingIds'];
      if (hidden is List) {
        hiddenBookingIds = hidden.map((item) => item.toString()).toList();
      }
    } catch (_) {
      _sessionToken = null;
      _sessionUser = null;
    }
    role = null;
    final savedToken = _sessionToken;
    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        final me = await _auth.me(savedToken);
        role = me.isOwner ? UserRole.owner : UserRole.customer;
        await _storeSession(savedToken, me);
        await _loadForCurrentRole();
      } on ApiException catch (error) {
        if (error.message.startsWith('Could not reach')) {
          role = _roleFrom(savedRoleName) ??
              (_sessionUser != null && _sessionUser!.isOwner ? UserRole.owner : UserRole.customer);
          _applySessionForRole();
        } else {
          role = null;
          await _clearAccount();
        }
      } catch (_) {
        role = null;
        await _clearAccount();
      }
    }
    _restoring = false;
    notifyListeners();
  }

  Future<({bool verified, String message})> registerShop({
    required String email,
    required String password,
    required String phone,
    required String shopName,
    required String address,
    required double latitude,
    required double longitude,
    required String imageBase64,
    required List<Map<String, dynamic>> services,
  }) async {
    return _auth.registerShop(
      email: email,
      password: password,
      phone: phone,
      shopName: shopName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      imageBase64: imageBase64,
      services: services,
    );
  }

  Future<void> confirmShopEmail(String email, String password) async {
    final result = await _auth.confirmEmail(email: email, password: password);
    _ensureRole(result.user);
    await _storeSession(result.token, result.user);
    await loadOwner();
  }

  Future<String> forgotPassword(String email) async {
    return _auth.forgotPassword(email: email);
  }

  Future<void> signIn(String email, String password) async {
    final result = await _auth.login(email: email, password: password);
    _ensureRole(result.user);
    await _storeSession(result.token, result.user);
    await _loadForCurrentRole();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final result = await _auth.signup(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role == UserRole.owner ? 'owner' : 'customer',
    );
    _ensureRole(result.user);
    await _storeSession(result.token, result.user);
    await _loadForCurrentRole();
  }

  Future<void> signOut() async {
    final current = token ?? _sessionToken;
    if (current != null) {
      try {
        await _auth.logout(current);
      } catch (_) {}
    }
    await _clearAccount();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final current = token ?? _sessionToken;
    if (current == null) {
      return;
    }
    await _auth.deleteAccount(current);
    role = null;
    await _clearAccount();
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_restoring || _clearingSession) {
      return;
    }
    if (token == null && _sessionToken == null) {
      return;
    }
    role = null;
    unawaited(_clearAccount().then((_) {
      if (hasListeners) {
        notifyListeners();
      }
    }));
  }

  Future<void> updateCustomerDetails({
    required String name,
    required String phone,
    required String location,
    String? avatar,
  }) async {
    profileLocation = location.trim().isEmpty ? profileLocation : location.trim();
    if (avatar != null) {
      avatarPath = avatar;
    }
    await updateProfile(name: name, phone: phone);
  }

  void setNotifications(bool enabled) {
    notificationsEnabled = enabled;
    notifyListeners();
    unawaited(_persist());
  }

  void clearBookingHistory() {
    hiddenBookingIds = appointments.map((item) => item.id).toList();
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> updateProfile({required String name, required String phone, String? email}) async {
    if (token == null) {
      return;
    }
    user = await _auth.update(token!, name: name, phone: phone, email: email);
    _sessionUser = user;
    await _persist();
    notifyListeners();
  }

  Future<List<ChatThread>> loadChats() async {
    final threads = await _api.chats();
    chatCount = threads.length;
    notifyListeners();
    return threads;
  }

  Stream<List<ChatThread>> watchChats() => _api.watchChats();

  Future<List<ChatLine>> loadMessages(String salonId, {String? customerId}) {
    return _api.messages(salonId, customerId: customerId);
  }

  Stream<List<ChatLine>> watchMessages(String salonId, {String? customerId}) {
    return _api.watchMessages(salonId, customerId: customerId);
  }

  Future<ChatLine> sendMessage(String salonId, String body, {String? customerId}) {
    return _api.sendMessage(salonId, body, customerId: customerId);
  }

  Future<void> deleteChat(String salonId, {String? customerId}) {
    return _api.deleteChat(salonId, customerId: customerId);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (token == null) {
      return;
    }
    await _auth.changePassword(token!, currentPassword: currentPassword, newPassword: newPassword);
  }

  Future<void> loadCustomer() async {
    await _run(() async {
      salons = await _api.listSalons();
    });
    if (isSignedIn) {
      try {
        appointments = await _api.appointments();
        final threads = await _api.chats();
        chatCount = threads.length;
        notifyListeners();
      } catch (_) {}
    }
    unawaited(_applyLocation());
  }

  Future<void> loadOwner() async {
    if (!isSignedIn) {
      return;
    }
    await _run(() async {
      stats = await _api.dashboard();
      ownerProfile = await _api.ownerSalon();
      ownerServices = await _api.ownerServices();
      appointments = await _api.appointments();
      try {
        final threads = await _api.chats();
        chatCount = threads.length;
      } catch (_) {
        chatCount = 0;
      }
    });
  }

  Future<void> refreshAppointments() async {
    if (!isSignedIn) {
      return;
    }
    appointments = await _api.appointments();
    if (role == UserRole.owner) {
      stats = await _api.dashboard();
    }
    notifyListeners();
  }

  Future<List<QueueBooking>> salonQueue(String salonId, DateTime date) async {
    final result = await _api.salonQueue(salonId, _ymd(date));
    return result.queue;
  }

  Future<Appointment> book({
    required Salon salon,
    required SalonService service,
    required DateTime date,
    required String time,
    required String gender,
  }) async {
    if (!isSignedIn) {
      throw const ApiException('Sign in from Profile to book.');
    }
    await _api.book(
      salonId: salon.id,
      serviceId: service.id,
      date: _ymd(date),
      time: time,
      gender: gender,
    );
    await refreshAppointments();
    return appointments.first;
  }

  Future<void> setStatus(String id, String status) async {
    await _api.updateStatus(id, status);
    await refreshAppointments();
  }

  Future<void> saveSalon(Map<String, dynamic> payload) async {
    ownerProfile = await _api.saveOwnerSalon(payload);
    notifyListeners();
  }

  Future<void> addService(Map<String, dynamic> payload) async {
    ownerServices = [...ownerServices, await _api.addService(payload)];
    notifyListeners();
  }

  Future<void> editService(String id, Map<String, dynamic> payload) async {
    final updated = await _api.updateService(id, payload);
    ownerServices = ownerServices.map((item) => item.id == id ? updated : item).toList();
    notifyListeners();
  }

  Future<void> removeService(String id) async {
    await _api.deleteService(id);
    ownerServices = ownerServices.where((item) => item.id != id).toList();
    notifyListeners();
  }

  void toggleSaved(String id) {
    if (savedSalonIds.contains(id)) {
      savedSalonIds = savedSalonIds.where((item) => item != id).toList();
    } else {
      savedSalonIds = [...savedSalonIds, id];
    }
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> retryLocation() => _applyLocation();

  Future<void> toggleTheme() async {
    darkMode = !darkMode;
    await _persist();
    notifyListeners();
  }

  void _applySessionForRole() {
    if (_sessionUser != null && _sessionToken != null && _matchesRole(_sessionUser!)) {
      user = _sessionUser;
      token = _sessionToken;
      _api.token = token;
      _api.currentUser = user;
    } else {
      user = null;
      token = null;
      _api.token = null;
      _api.currentUser = null;
    }
  }

  bool _matchesRole(AppUser account) {
    return role == UserRole.owner ? account.isOwner : !account.isOwner;
  }

  void _ensureRole(AppUser account) {
    if (role == UserRole.owner && !account.isOwner) {
      throw const ApiException('This account is for customers. Go back and choose Customer.');
    }
    if (role != UserRole.owner && account.isOwner) {
      throw const ApiException('This account is for salon owners. Go back and choose Salon Owner.');
    }
  }

  Future<void> _loadForCurrentRole() async {
    if (role == UserRole.owner) {
      await loadOwner();
    } else {
      await loadCustomer();
    }
  }

  Future<void> _applyLocation() async {
    final location = await _location.current();
    locationMessage = location.message;
    locationEnabled = location.usedGps;
    userLatitude = location.latitude;
    userLongitude = location.longitude;
    if (location.usedGps && location.latitude != null && location.longitude != null) {
      try {
        final nearby = await _api.listNearby(lat: location.latitude!, lng: location.longitude!);
        if (nearby.isEmpty) {
          locationEnabled = false;
          locationMessage = 'No salons within 10 km. Showing all salons.';
        } else {
          salons = nearby;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _storeSession(String nextToken, AppUser nextUser) async {
    token = nextToken;
    user = nextUser;
    _sessionToken = nextToken;
    _sessionUser = nextUser;
    _api.token = nextToken;
    _api.currentUser = nextUser;
    await _persist();
    notifyListeners();
  }

  Future<void> _clearAccount() async {
    if (_clearingSession) {
      return;
    }
    _clearingSession = true;
    try {
      token = null;
      user = null;
      _sessionToken = null;
      _sessionUser = null;
      _api.token = null;
      _api.currentUser = null;
      appointments = [];
      stats = null;
      ownerProfile = null;
      ownerServices = [];
      await _persist();
    } finally {
      _clearingSession = false;
    }
  }

  Future<void> _persist() async {
    final saved = await SessionStore.read();
    saved.remove('password');
    saved.remove('currentPassword');
    saved.remove('newPassword');
    saved['darkMode'] = darkMode;
    saved['profileLocation'] = profileLocation;
    saved['notificationsEnabled'] = notificationsEnabled;
    saved['savedSalonIds'] = savedSalonIds;
    saved['hiddenBookingIds'] = hiddenBookingIds;
    if (avatarPath != null) {
      saved['avatarPath'] = avatarPath;
    }
    if (role != null) {
      saved['role'] = role == UserRole.owner ? 'owner' : 'customer';
    } else {
      saved.remove('role');
    }
    if (_sessionToken != null) {
      saved['token'] = _sessionToken;
    } else {
      saved.remove('token');
    }
    if (_sessionUser != null) {
      final account = _sessionUser!.toJson();
      account.remove('password');
      saved['user'] = account;
    } else {
      saved.remove('user');
    }
    if (ApiConfig.runtimeOverride != null) {
      saved['apiBaseUrl'] = ApiConfig.runtimeOverride;
    }
    await SessionStore.write(saved);
  }

  UserRole? _roleFrom(String? value) {
    if (value == 'owner') {
      return UserRole.owner;
    }
    if (value == 'customer') {
      return UserRole.customer;
    }
    return null;
  }

  Future<void> _run(Future<void> Function() work) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await work();
    } on ApiException catch (item) {
      error = item.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _ymd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
