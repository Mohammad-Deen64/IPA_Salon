import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../utils/gmail.dart';
import 'api_exception.dart';
import 'password_hasher.dart';

class AuthService {
  AuthService({FirebaseFirestore? firestore, http.Client? client, this.onUnauthorized})
      : _db = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  final FirebaseFirestore _db;
  final http.Client _client;
  void Function()? onUnauthorized;

  static const _apiKey = 'AIzaSyDNpRg0NWRoKaEM2TusUHJ5EnvmyYBgLiI';

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _salons => _db.collection('salons');
  CollectionReference<Map<String, dynamic>> get _services => _db.collection('services');

  Future<({String token, AppUser user})> signup({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    final cleaned = _requireGmail(email);
    if (role != 'customer' && role != 'owner') {
      throw const ApiException('Role must be customer or owner.');
    }
    if (password.length < 6) {
      throw const ApiException('Password must be at least 6 characters.');
    }
    final existing = await _users.where('email', isEqualTo: cleaned).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw const ApiException('An account with this email already exists.');
    }
    final id = _newId('u');
    final user = AppUser(
      id: id,
      email: cleaned,
      name: name.trim().isEmpty ? cleaned.split('@').first : name.trim(),
      phone: phone.trim(),
      role: role,
    );
    final payload = <String, dynamic>{
      'id': id,
      'email': cleaned,
      'password_hash': await PasswordHasher.hash(password),
      'name': user.name,
      'phone': user.phone,
      'role': role,
      'is_active': true,
      'email_verified': true,
      'avatar': '',
      'salon_id': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (role == 'owner') {
      final salonId = _newId('salon');
      await _salons.doc(salonId).set({
        'id': salonId,
        'name': "${user.name}'s Salon",
        'description': 'Owner salon created at sign-up.',
        'address': 'Islamabad, Pakistan',
        'latitude': 33.6844,
        'longitude': 73.0479,
        'phone': user.phone,
        'email': cleaned,
        'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
        'opens_at': '9 AM',
        'open_until': '9 PM',
        'rating': 5.0,
        'review_count': 0,
        'tags': jsonEncode(['New']),
        'available_slots': jsonEncode(['10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM']),
        'is_demo': false,
      });
      final serviceId = _newId('s');
      await _services.doc(serviceId).set({
        'id': serviceId,
        'salon_id': salonId,
        'name': 'Haircut',
        'male_price': 25,
        'female_price': 35,
        'duration': 45,
        'category': 'Hair',
      });
      payload['salon_id'] = salonId;
    }
    await _users.doc(id).set(payload);
    await _ensureFirebaseAuthUser(cleaned, password);
    final token = await _issueToken(id);
    return (token: token, user: user.copyWith(salonId: payload['salon_id'] as String?));
  }

  Future<({String token, AppUser user})> login({
    required String email,
    required String password,
  }) async {
    final cleaned = email.trim().toLowerCase();
    final snap = await _users.where('email', isEqualTo: cleaned).limit(1).get();
    if (snap.docs.isEmpty) {
      throw const ApiException('Invalid email or password.');
    }
    final doc = snap.docs.first;
    final data = doc.data();
    if (data['is_active'] == false) {
      throw const ApiException('Invalid email or password.');
    }
    final hash = data['password_hash'] as String? ?? '';
    var ok = await PasswordHasher.verify(password, hash);
    if (!ok) {
      ok = await _firebasePasswordMatches(cleaned, password);
      if (ok) {
        await doc.reference.update({'password_hash': await PasswordHasher.hash(password)});
      }
    }
    if (!ok) {
      throw const ApiException('Invalid email or password.');
    }
    if ((data['role'] as String?) == 'owner' && data['email_verified'] == false) {
      throw const ApiException('Open the verification message in your Gmail and tap the link, then sign in.');
    }
    final user = _userFrom(data);
    final token = await _issueToken(user.id);
    return (token: token, user: user);
  }

  Future<String> forgotPassword({required String email}) async {
    final cleaned = _requireGmail(email);
    final snap = await _users.where('email', isEqualTo: cleaned).limit(1).get();
    if (snap.docs.isEmpty || snap.docs.first.data()['is_active'] == false) {
      throw const ApiException('No account uses this Gmail address.');
    }
    await _sendPasswordReset(cleaned);
    return 'Check your Gmail and open the reset link. Then sign in here with your new password.';
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
    final cleaned = _requireGmail(email);
    if (password.length < 6) {
      throw const ApiException('Password must be at least 6 characters.');
    }
    if (shopName.trim().isEmpty || address.trim().isEmpty || phone.trim().isEmpty) {
      throw const ApiException('Shop name, location, and phone are required.');
    }
    if (services.isEmpty) {
      throw const ApiException('Add a price for at least one speciality.');
    }
    final existing = await _users.where('email', isEqualTo: cleaned).limit(1).get();
    if (existing.docs.isNotEmpty) {
      final row = existing.docs.first.data();
      final hash = row['password_hash'] as String? ?? '';
      final verified = row['email_verified'] == true;
      final passwordOk = await PasswordHasher.verify(password, hash);
      if (verified || !passwordOk) {
        throw const ApiException('An account with this email already exists.');
      }
    } else {
      final userId = _newId('u');
      final salonId = _newId('salon');
      await _users.doc(userId).set({
        'id': userId,
        'email': cleaned,
        'password_hash': await PasswordHasher.hash(password),
        'name': shopName.trim(),
        'phone': phone.trim(),
        'role': 'owner',
        'is_active': true,
        'email_verified': false,
        'avatar': '',
        'salon_id': salonId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _salons.doc(salonId).set({
        'id': salonId,
        'name': shopName.trim(),
        'description': 'Specialities: ${services.map((item) => item['name']).join(', ')}',
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone.trim(),
        'email': cleaned,
        'image': 'data:image/jpeg;base64,$imageBase64',
        'opens_at': '9 AM',
        'open_until': '9 PM',
        'rating': 5.0,
        'review_count': 0,
        'tags': jsonEncode(['New']),
        'available_slots': jsonEncode(['10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM']),
        'is_demo': false,
      });
      for (final item in services) {
        final serviceId = _newId('s');
        final price = (item['price'] as num).toDouble();
        await _services.doc(serviceId).set({
          'id': serviceId,
          'salon_id': salonId,
          'name': item['name'],
          'male_price': price,
          'female_price': price,
          'duration': 45,
          'category': 'Hair',
        });
      }
    }
    final status = await _sendGmailVerification(cleaned, password);
    if (status == 'already_verified') {
      await confirmEmail(email: cleaned, password: password);
      return (verified: true, message: 'Gmail already verified.');
    }
    return (verified: false, message: 'Check your Gmail and tap the verification link, then continue.');
  }

  Future<({String token, AppUser user})> confirmEmail({
    required String email,
    required String password,
  }) async {
    final cleaned = email.trim().toLowerCase();
    final verified = await _gmailIsVerified(cleaned, password);
    if (!verified) {
      throw const ApiException('Your Gmail is not verified yet. Open the message and tap the link.');
    }
    final snap = await _users.where('email', isEqualTo: cleaned).limit(1).get();
    if (snap.docs.isEmpty) {
      throw const ApiException('Account not found.');
    }
    await snap.docs.first.reference.update({'email_verified': true});
    final user = _userFrom(snap.docs.first.data());
    final token = await _issueToken(user.id);
    return (token: token, user: user);
  }

  Future<AppUser> me(String token) async {
    final user = await _userFromToken(token);
    if (user == null) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    return user;
  }

  Future<AppUser> update(String token, {String? name, String? phone, String? email}) async {
    final user = await _userFromToken(token);
    if (user == null) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name.trim().isEmpty ? user.name : name.trim();
    }
    if (phone != null) {
      updates['phone'] = phone.trim();
    }
    if (email != null) {
      final cleaned = email.trim().toLowerCase();
      if (cleaned.isNotEmpty && cleaned != user.email) {
        if (!isGmailAddress(cleaned)) {
          throw const ApiException(gmailFormatError);
        }
        final taken = await _users.where('email', isEqualTo: cleaned).limit(1).get();
        if (taken.docs.any((doc) => doc.id != user.id)) {
          throw const ApiException('An account with this email already exists.');
        }
        updates['email'] = cleaned;
      }
    }
    if (updates.isNotEmpty) {
      await _users.doc(user.id).update(updates);
    }
    final fresh = await _users.doc(user.id).get();
    return _userFrom(fresh.data() ?? {});
  }

  Future<void> changePassword(String token, {required String currentPassword, required String newPassword}) async {
    final user = await _userFromToken(token);
    if (user == null) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    final doc = await _users.doc(user.id).get();
    final hash = doc.data()?['password_hash'] as String? ?? '';
    if (!await PasswordHasher.verify(currentPassword, hash)) {
      throw const ApiException('Current password is incorrect.');
    }
    if (newPassword.length < 6) {
      throw const ApiException('Password must be at least 6 characters.');
    }
    await _users.doc(user.id).update({'password_hash': await PasswordHasher.hash(newPassword)});
  }

  Future<void> logout(String token) async {
    await _sessions.doc(token).delete();
  }

  Future<void> deleteAccount(String token) async {
    final user = await _userFromToken(token);
    if (user == null) {
      return;
    }
    await logout(token);
    await _users.doc(user.id).update({
      'is_active': false,
      'email': 'deleted+${user.id}@invalid.local',
      'password_hash': await PasswordHasher.hash(_newId('x')),
    });
  }

  Future<AppUser?> _userFromToken(String token) async {
    final session = await _sessions.doc(token).get();
    if (!session.exists) {
      return null;
    }
    final createdRaw = session.data()?['created_at'] as String?;
    if (createdRaw != null) {
      final created = DateTime.tryParse(createdRaw);
      if (created != null && DateTime.now().toUtc().difference(created).inDays > 7) {
        await session.reference.delete();
        return null;
      }
    }
    final userId = session.data()?['user_id'] as String?;
    if (userId == null) {
      return null;
    }
    final userDoc = await _users.doc(userId).get();
    final data = userDoc.data();
    if (data == null || data['is_active'] == false) {
      return null;
    }
    return _userFrom(data);
  }

  Future<String> _issueToken(String userId) async {
    final token = List.generate(32, (_) => Random.secure().nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _sessions.doc(token).set({
      'token': token,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return token;
  }

  AppUser _userFrom(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] as String,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      salonId: data['salon_id'] as String?,
      avatar: data['avatar'] as String? ?? '',
    );
  }

  String _requireGmail(String email) {
    final cleaned = email.trim().toLowerCase();
    if (!isGmailAddress(cleaned)) {
      throw const ApiException(gmailFormatError);
    }
    return cleaned;
  }

  String _newId(String prefix) {
    final hex = List.generate(4, (_) => Random.secure().nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$prefix$hex';
  }

  Future<Map<String, dynamic>> _identity(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/$path?key=$_apiKey');
    final response = await _client.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = ((decoded['error'] as Map?)?['message'] as String?) ?? 'EMAIL_FAILED';
    throw ApiException(message.split(' : ').first);
  }

  Future<void> _ensureFirebaseAuthUser(String email, String password) async {
    try {
      await _identity('accounts:signUp', {'email': email, 'password': password, 'returnSecureToken': true});
    } on ApiException catch (error) {
      if (error.message != 'EMAIL_EXISTS') {
        // Signup can continue without Firebase Auth when Email/Password is still off.
      }
    } catch (_) {}
  }

  Future<bool> _firebasePasswordMatches(String email, String password) async {
    try {
      await _identity('accounts:signInWithPassword', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await _identity('accounts:sendOobCode', {'requestType': 'PASSWORD_RESET', 'email': email});
      return;
    } on ApiException catch (error) {
      if (error.message != 'EMAIL_NOT_FOUND') {
        throw ApiException(_friendlyMail(error.message));
      }
    }
    final temporary = '${_newId('tmp')}Aa1!';
    try {
      await _identity('accounts:signUp', {'email': email, 'password': temporary, 'returnSecureToken': true});
    } on ApiException catch (error) {
      if (error.message != 'EMAIL_EXISTS') {
        throw ApiException(_friendlyMail(error.message));
      }
    }
    try {
      await _identity('accounts:sendOobCode', {'requestType': 'PASSWORD_RESET', 'email': email});
    } on ApiException catch (error) {
      throw ApiException(_friendlyMail(error.message));
    }
  }

  Future<String> _sendGmailVerification(String email, String password) async {
    final token = await _firebaseToken(email, password);
    final lookup = await _identity('accounts:lookup', {'idToken': token.$1});
    final users = (lookup['users'] as List?) ?? const [];
    final already = token.$2 || (users.isNotEmpty && users.first is Map && (users.first as Map)['emailVerified'] == true);
    if (already) {
      return 'already_verified';
    }
    await _identity('accounts:sendOobCode', {'requestType': 'VERIFY_EMAIL', 'idToken': token.$1});
    return 'sent';
  }

  Future<bool> _gmailIsVerified(String email, String password) async {
    final token = await _firebaseToken(email, password);
    if (token.$2) {
      return true;
    }
    final lookup = await _identity('accounts:lookup', {'idToken': token.$1});
    final users = (lookup['users'] as List?) ?? const [];
    return users.isNotEmpty && users.first is Map && (users.first as Map)['emailVerified'] == true;
  }

  Future<(String, bool)> _firebaseToken(String email, String password) async {
    try {
      final created = await _identity('accounts:signUp', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      return (created['idToken'] as String, false);
    } on ApiException catch (error) {
      if (error.message != 'EMAIL_EXISTS') {
        throw ApiException(_friendlyMail(error.message));
      }
    }
    try {
      final signed = await _identity('accounts:signInWithPassword', {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      });
      final lookup = await _identity('accounts:lookup', {'idToken': signed['idToken']});
      final users = (lookup['users'] as List?) ?? const [];
      final verified = users.isNotEmpty && users.first is Map && (users.first as Map)['emailVerified'] == true;
      return (signed['idToken'] as String, verified);
    } on ApiException catch (error) {
      throw ApiException(_friendlyMail(error.message));
    }
  }

  String _friendlyMail(String code) {
    if (code == 'OPERATION_NOT_ALLOWED') {
      return 'Gmail verification is not enabled yet. In Firebase console, open Authentication, enable Email/Password, and try again.';
    }
    if (code == 'INVALID_EMAIL') {
      return gmailFormatError;
    }
    if (code == 'WEAK_PASSWORD') {
      return 'Password must be at least 6 characters.';
    }
    if (code == 'EMAIL_NOT_FOUND' || code == 'INVALID_PASSWORD') {
      return 'Email or password does not match the verification message.';
    }
    if (code == 'TOO_MANY_ATTEMPTS_TRY_LATER') {
      return 'Too many emails were sent. Wait a few minutes and try again.';
    }
    return 'Could not send the Gmail verification message.';
  }
}

extension on AppUser {
  AppUser copyWith({String? salonId}) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      phone: phone,
      role: role,
      salonId: salonId ?? this.salonId,
      avatar: avatar,
    );
  }
}
