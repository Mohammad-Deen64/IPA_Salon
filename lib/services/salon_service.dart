import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/chat.dart';
import '../models/salon.dart';
import '../models/user.dart';
import 'api_exception.dart';
import 'booking_hours.dart';

class SalonServiceApi {
  SalonServiceApi({FirebaseFirestore? firestore, this.onUnauthorized})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  void Function()? onUnauthorized;
  String? token;
  AppUser? currentUser;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _salons => _db.collection('salons');
  CollectionReference<Map<String, dynamic>> get _services => _db.collection('services');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chat_messages');
  CollectionReference<Map<String, dynamic>> get _chatDeletes => _db.collection('chat_deletes');

  Future<List<Salon>> listSalons() => _collectSalons();

  Future<List<Salon>> listNearby({required double lat, required double lng, double radiusKm = 10}) {
    return _collectSalons(lat: lat, lng: lng, radiusKm: radiusKm, nearbyOnly: true);
  }

  Future<Salon> salon(String id) async {
    final rows = await _collectSalons();
    return rows.firstWhere((item) => item.id == id, orElse: () => throw const ApiException('Salon not found.'));
  }

  Future<({String opensAt, String openUntil, List<QueueBooking> queue})> salonQueue(String salonId, String date) async {
    final salonDoc = await _salons.doc(salonId).get();
    final salonData = salonDoc.data() ?? {};
    final bookings = await _bookings.where('salon_id', isEqualTo: salonId).where('date', isEqualTo: date).get();
    final services = await _services.where('salon_id', isEqualTo: salonId).get();
    final serviceById = {for (final doc in services.docs) doc.id: doc.data()};
    final queue = <QueueBooking>[];
    for (final doc in bookings.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      if (status == 'rejected' || status == 'cancelled') {
        continue;
      }
      final service = serviceById[data['service_id']];
      queue.add(
        QueueBooking(
          time: data['time'] as String? ?? '',
          duration: (service?['duration'] as num?)?.toInt() ?? 45,
          serviceName: service?['name'] as String? ?? '',
        ),
      );
    }
    return (
      opensAt: salonData['opens_at'] as String? ?? '9 AM',
      openUntil: salonData['open_until'] as String? ?? '9 PM',
      queue: queue,
    );
  }

  Future<List<Appointment>> appointments() async {
    final user = await _requireUser();
    QuerySnapshot<Map<String, dynamic>> snap;
    if (user.isOwner) {
      if (user.salonId == null) {
        return [];
      }
      snap = await _bookings.where('salon_id', isEqualTo: user.salonId).get();
    } else {
      snap = await _bookings.where('customer_id', isEqualTo: user.id).get();
    }
    final rows = <Appointment>[];
    for (final doc in snap.docs) {
      rows.add(await _appointmentFrom(doc.data()));
    }
    rows.sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));
    return rows;
  }

  Future<Appointment> book({
    required String salonId,
    required String serviceId,
    required String date,
    required String time,
    required String gender,
    String? customerName,
    String? customerPhone,
  }) async {
    final user = await _requireUser();
    if (user.isOwner) {
      throw const ApiException('Only customers can create bookings.');
    }
    final salonDoc = await _salons.doc(salonId).get();
    if (!salonDoc.exists) {
      throw const ApiException('Salon not found.');
    }
    final serviceDoc = await _services.doc(serviceId).get();
    final service = serviceDoc.data();
    if (service == null || service['salon_id'] != salonId) {
      throw const ApiException('Service not found.');
    }
    final priceGender = gender == 'female' ? 'female_price' : 'male_price';
    var price = (service[priceGender] as num?)?.toDouble() ?? 0;
    if (price <= 0) {
      price = (service['male_price'] as num?)?.toDouble() ?? (service['female_price'] as num?)?.toDouble() ?? 0;
    }
    final id = _newId('b');
    final payload = {
      'id': id,
      'customer_id': user.id,
      'salon_id': salonId,
      'service_id': serviceId,
      'date': date,
      'time': time,
      'price': price,
      'status': 'pending',
      'gender': gender,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _bookings.doc(id).set(payload);
    final messageId = _newId('m');
    await _chats.doc(messageId).set({
      'id': messageId,
      'salon_id': salonId,
      'customer_id': user.id,
      'booking_id': id,
      'sender_role': 'system',
      'body': 'Booking requested for $date at $time (${service['name']}).',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await _chatDeletes.doc('${salonId}_${user.id}').delete();
    return _appointmentFrom(payload);
  }

  Future<Appointment> updateStatus(String id, String status) async {
    await _requireUser();
    final doc = await _bookings.doc(id).get();
    if (!doc.exists) {
      throw const ApiException('Booking not found.');
    }
    await doc.reference.update({'status': status});
    final data = {...doc.data()!, 'status': status};
    return _appointmentFrom(data);
  }

  Future<OwnerStats> dashboard() async {
    final user = await _requireUser();
    if (!user.isOwner || user.salonId == null) {
      throw const ApiException('Owner has no salon.');
    }
    final salon = await _salons.doc(user.salonId!).get();
    final bookings = await _bookings.where('salon_id', isEqualTo: user.salonId).get();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    var todayBookings = 0;
    var pending = 0;
    var completed = 0;
    var revenue = 0.0;
    var weekTotal = 0;
    var weekRevenue = 0.0;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    for (final doc in bookings.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final date = data['date'] as String? ?? '';
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      if (date == today) {
        todayBookings += 1;
      }
      if (status == 'pending') {
        pending += 1;
      }
      if (status == 'completed') {
        completed += 1;
        revenue += price;
      }
      final parsed = DateTime.tryParse(date);
      if (parsed != null && !parsed.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
        weekTotal += 1;
        if (status == 'completed' || status == 'accepted') {
          weekRevenue += price;
        }
      }
    }
    return OwnerStats(
      todayBookings: todayBookings,
      pending: pending,
      completed: completed,
      revenue: revenue,
      weekTotal: weekTotal,
      rating: (salon.data()?['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (salon.data()?['review_count'] as num?)?.toInt() ?? 0,
      weekRevenue: weekRevenue,
    );
  }

  Future<Salon> ownerSalon() async {
    final user = await _requireUser();
    if (user.salonId == null) {
      throw const ApiException('Owner has no salon.');
    }
    return salon(user.salonId!);
  }

  Future<Salon> saveOwnerSalon(Map<String, dynamic> payload) async {
    final user = await _requireUser();
    if (user.salonId == null) {
      throw const ApiException('Owner has no salon.');
    }
    final updates = <String, dynamic>{};
    if (payload['name'] != null) updates['name'] = payload['name'];
    if (payload['description'] != null) updates['description'] = payload['description'];
    if (payload['location'] != null) updates['address'] = payload['location'];
    if (payload['phone'] != null) updates['phone'] = payload['phone'];
    if (payload['email'] != null) updates['email'] = payload['email'];
    if (payload['opens_at'] != null) updates['opens_at'] = payload['opens_at'];
    if (payload['open_until'] != null) updates['open_until'] = payload['open_until'];
    if (payload['image_base64'] != null) {
      updates['image'] = 'data:image/jpeg;base64,${payload['image_base64']}';
    }
    if (payload['owner_name'] != null) {
      await _users.doc(user.id).update({'name': payload['owner_name']});
      currentUser = AppUser(
        id: user.id,
        email: user.email,
        name: payload['owner_name'] as String,
        phone: user.phone,
        role: user.role,
        salonId: user.salonId,
        avatar: user.avatar,
      );
    }
    if (payload['owner_image_base64'] != null) {
      await _users.doc(user.id).update({'avatar': 'data:image/jpeg;base64,${payload['owner_image_base64']}'});
    }
    if (updates.isNotEmpty) {
      await _salons.doc(user.salonId!).update(updates);
    }
    return salon(user.salonId!);
  }

  Future<List<SalonService>> ownerServices() async {
    final user = await _requireUser();
    if (user.salonId == null) {
      return [];
    }
    final snap = await _services.where('salon_id', isEqualTo: user.salonId).get();
    return snap.docs.map((doc) => _serviceFrom(doc.data())).toList();
  }

  Future<SalonService> addService(Map<String, dynamic> payload) async {
    final user = await _requireUser();
    if (user.salonId == null) {
      throw const ApiException('Owner has no salon.');
    }
    final id = _newId('s');
    final data = {
      'id': id,
      'salon_id': user.salonId,
      'name': payload['name'],
      'male_price': payload['male_price'],
      'female_price': payload['female_price'],
      'duration': payload['duration'] ?? 45,
      'category': payload['category'] ?? 'Hair',
    };
    await _services.doc(id).set(data);
    return _serviceFrom(data);
  }

  Future<SalonService> updateService(String id, Map<String, dynamic> payload) async {
    final user = await _requireUser();
    final doc = await _services.doc(id).get();
    if (!doc.exists || doc.data()?['salon_id'] != user.salonId) {
      throw const ApiException('Service not found.');
    }
    final updates = <String, dynamic>{};
    for (final key in ['name', 'male_price', 'female_price', 'duration', 'category']) {
      if (payload[key] != null) {
        updates[key] = payload[key];
      }
    }
    await doc.reference.update(updates);
    return _serviceFrom({...doc.data()!, ...updates});
  }

  Future<void> deleteService(String id) async {
    final user = await _requireUser();
    final doc = await _services.doc(id).get();
    if (!doc.exists || doc.data()?['salon_id'] != user.salonId) {
      throw const ApiException('Service not found.');
    }
    await doc.reference.delete();
  }

  Future<List<ChatThread>> chats() async {
    final user = await _requireUser();
    await _ensureBookingChats(user);
    QuerySnapshot<Map<String, dynamic>> snap;
    if (user.isOwner) {
      if (user.salonId == null) {
        return [];
      }
      snap = await _chats.where('salon_id', isEqualTo: user.salonId).get();
    } else {
      snap = await _chats.where('customer_id', isEqualTo: user.id).get();
    }
    final grouped = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final key = '${data['salon_id']}|${data['customer_id']}';
      final current = grouped[key];
      if (current == null) {
        grouped[key] = doc;
        continue;
      }
      final currentAt = DateTime.tryParse(current.data()['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final nextAt = DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (!nextAt.isBefore(currentAt)) {
        grouped[key] = doc;
      }
    }
    final threads = <ChatThread>[];
    for (final doc in grouped.values) {
      final data = doc.data();
      final salonId = data['salon_id'] as String;
      final customerId = data['customer_id'] as String;
      String title = 'Chat';
      if (user.isOwner) {
        final customer = await _users.doc(customerId).get();
        title = customer.data()?['name'] as String? ?? 'Customer';
      } else {
        final salon = await _salons.doc(salonId).get();
        title = salon.data()?['name'] as String? ?? 'Salon';
      }
      threads.add(
        ChatThread(
          salonId: salonId,
          customerId: customerId,
          title: title,
          lastMessage: data['body'] as String? ?? '',
        ),
      );
    }
    return threads;
  }

  Stream<List<ChatThread>> watchChats() async* {
    final user = await _requireUser();
    await _ensureBookingChats(user);
    final query = user.isOwner
        ? _chats.where('salon_id', isEqualTo: user.salonId)
        : _chats.where('customer_id', isEqualTo: user.id);
    await for (final _ in query.snapshots()) {
      yield await chats();
    }
  }

  Future<List<ChatLine>> messages(String salonId, {String? customerId}) async {
    final user = await _requireUser();
    final other = user.isOwner ? (customerId ?? (throw const ApiException('Choose a customer to message.'))) : user.id;
    if (user.isOwner && user.salonId != salonId) {
      throw const ApiException('This chat is for another salon.');
    }
    if (!user.isOwner && other != user.id) {
      throw const ApiException('This chat is for another customer.');
    }
    final snap = await _chats.where('salon_id', isEqualTo: salonId).where('customer_id', isEqualTo: other).get();
    final rows = snap.docs.map((doc) => doc.data()).toList()
      ..sort((a, b) => (a['created_at'] as String? ?? '').compareTo(b['created_at'] as String? ?? ''));
    return rows.map((data) => _lineFrom(data, user)).toList();
  }

  Stream<List<ChatLine>> watchMessages(String salonId, {String? customerId}) async* {
    final user = await _requireUser();
    final other = user.isOwner ? (customerId ?? (throw const ApiException('Choose a customer to message.'))) : user.id;
    await for (final snap in _chats.where('salon_id', isEqualTo: salonId).where('customer_id', isEqualTo: other).snapshots()) {
      final rows = snap.docs.map((doc) => doc.data()).toList()
        ..sort((a, b) => (a['created_at'] as String? ?? '').compareTo(b['created_at'] as String? ?? ''));
      yield rows.map((data) => _lineFrom(data, user)).toList();
    }
  }

  Future<ChatLine> sendMessage(String salonId, String body, {String? customerId}) async {
    final user = await _requireUser();
    final text = body.trim();
    if (text.isEmpty) {
      throw const ApiException('Write a message first.');
    }
    final other = user.isOwner ? (customerId ?? (throw const ApiException('Choose a customer to message.'))) : user.id;
    if (user.isOwner && user.salonId != salonId) {
      throw const ApiException('This chat is for another salon.');
    }
    if (!user.isOwner && other != user.id) {
      throw const ApiException('This chat is for another customer.');
    }
    final id = _newId('m');
    final data = {
      'id': id,
      'salon_id': salonId,
      'customer_id': other,
      'booking_id': null,
      'sender_role': user.isOwner ? 'owner' : 'customer',
      'body': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _chats.doc(id).set(data);
    await _chatDeletes.doc('${salonId}_$other').delete();
    return _lineFrom(data, user);
  }

  Future<void> deleteChat(String salonId, {String? customerId}) async {
    final user = await _requireUser();
    final other = user.isOwner ? (customerId ?? (throw const ApiException('Choose a customer chat to delete.'))) : user.id;
    if (user.isOwner && user.salonId != salonId) {
      throw const ApiException('This chat is for another salon.');
    }
    if (!user.isOwner && other != user.id) {
      throw const ApiException('This chat is for another customer.');
    }
    final snap = await _chats.where('salon_id', isEqualTo: salonId).where('customer_id', isEqualTo: other).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_chatDeletes.doc('${salonId}_$other'), {
      'salon_id': salonId,
      'customer_id': other,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_by': user.id,
    });
    await batch.commit();
  }

  Future<List<Salon>> _collectSalons({double? lat, double? lng, double radiusKm = 10, bool nearbyOnly = false}) async {
    final salonSnap = await _salons.get();
    final serviceSnap = await _services.get();
    final ownerSnap = await _users.where('role', isEqualTo: 'owner').get();
    final servicesBySalon = <String, List<Map<String, dynamic>>>{};
    for (final doc in serviceSnap.docs) {
      final data = doc.data();
      final salonId = data['salon_id'] as String? ?? '';
      servicesBySalon.putIfAbsent(salonId, () => []).add(data);
    }
    final ownersBySalon = <String, Map<String, dynamic>>{};
    for (final doc in ownerSnap.docs) {
      final data = doc.data();
      if (data['is_active'] == false) {
        continue;
      }
      final salonId = data['salon_id'] as String?;
      if (salonId == null) {
        continue;
      }
      ownersBySalon[salonId] = data;
    }
    final rows = <Salon>[];
    for (final doc in salonSnap.docs) {
      final data = doc.data();
      final owner = ownersBySalon[doc.id];
      if (owner != null && owner['email_verified'] == false) {
        continue;
      }
      final salonLat = (data['latitude'] as num?)?.toDouble();
      final salonLng = (data['longitude'] as num?)?.toDouble();
      double? distance;
      if (lat != null && lng != null && salonLat != null && salonLng != null) {
        distance = _haversineKm(lat, lng, salonLat, salonLng);
        if (nearbyOnly && distance > radiusKm) {
          continue;
        }
      } else if (nearbyOnly) {
        continue;
      }
      rows.add(
        _salonFrom(
          data,
          servicesBySalon[doc.id] ?? const [],
          ownerName: owner?['name'] as String?,
          ownerImage: owner?['avatar'] as String?,
          distanceKm: distance,
        ),
      );
    }
    if (lat != null && lng != null) {
      rows.sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    }
    return rows;
  }

  Future<void> _ensureBookingChats(AppUser user) async {
    QuerySnapshot<Map<String, dynamic>> bookings;
    if (user.isOwner) {
      if (user.salonId == null) {
        return;
      }
      bookings = await _bookings.where('salon_id', isEqualTo: user.salonId).get();
    } else {
      bookings = await _bookings.where('customer_id', isEqualTo: user.id).get();
    }
    for (final doc in bookings.docs) {
      final booking = doc.data();
      final deleted = await _chatDeletes.doc('${booking['salon_id']}_${booking['customer_id']}').get();
      if (deleted.exists) {
        continue;
      }
      final existing = await _chats.where('booking_id', isEqualTo: booking['id']).limit(1).get();
      if (existing.docs.isNotEmpty) {
        continue;
      }
      final salon = await _salons.doc(booking['salon_id'] as String).get();
      final service = await _services.doc(booking['service_id'] as String).get();
      final id = _newId('m');
      await _chats.doc(id).set({
        'id': id,
        'salon_id': booking['salon_id'],
        'customer_id': booking['customer_id'],
        'booking_id': booking['id'],
        'sender_role': 'system',
        'body':
            'Booking ${booking['status']} for ${booking['date']} at ${booking['time']} (${service.data()?['name'] ?? 'service'}) at ${salon.data()?['name'] ?? 'salon'}.',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<AppUser> _requireUser() async {
    if (currentUser != null && token != null) {
      return currentUser!;
    }
    if (token == null) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    final session = await _sessions.doc(token!).get();
    if (!session.exists) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    final userId = session.data()?['user_id'] as String?;
    final userDoc = userId == null ? null : await _users.doc(userId).get();
    final data = userDoc?.data();
    if (data == null || data['is_active'] == false) {
      onUnauthorized?.call();
      throw const ApiException('Please sign in.');
    }
    currentUser = AppUser(
      id: data['id'] as String,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      salonId: data['salon_id'] as String?,
      avatar: data['avatar'] as String? ?? '',
    );
    return currentUser!;
  }

  Future<Appointment> _appointmentFrom(Map<String, dynamic> data) async {
    final salon = await _salons.doc(data['salon_id'] as String).get();
    final service = await _services.doc(data['service_id'] as String).get();
    final customer = await _users.doc(data['customer_id'] as String).get();
    return Appointment(
      id: data['id'] as String,
      salonId: data['salon_id'] as String,
      salonName: salon.data()?['name'] as String? ?? '',
      serviceName: service.data()?['name'] as String? ?? '',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'pending',
      customerName: customer.data()?['name'] as String? ?? '',
      customerPhone: customer.data()?['phone'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      duration: (service.data()?['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Salon _salonFrom(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> services, {
    String? ownerName,
    String? ownerImage,
    double? distanceKm,
  }) {
    final parsedServices = services.map(_serviceFrom).toList();
    final prices = parsedServices.map((item) => item.malePrice > 0 ? item.malePrice : item.femalePrice).where((item) => item > 0);
    return Salon(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      distance: distanceKm == null ? '—' : '${distanceKm.toStringAsFixed(1)} km',
      startingPrice: prices.isEmpty ? 0 : prices.reduce(min),
      image: data['image'] as String? ?? '',
      location: data['address'] as String? ?? data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      opensAt: data['opens_at'] as String? ?? '9 AM',
      openUntil: data['open_until'] as String? ?? '9 PM',
      tags: _stringList(data['tags']),
      availableSlots: _stringList(data['available_slots']),
      services: parsedServices,
      ownerName: ownerName,
      ownerImage: ownerImage,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      distanceKm: distanceKm,
      isDemo: data['is_demo'] == true,
    );
  }

  SalonService _serviceFrom(Map<String, dynamic> data) {
    return SalonService(
      id: data['id'] as String,
      name: data['name'] as String? ?? '',
      malePrice: (data['male_price'] as num?)?.toDouble() ?? 0,
      femalePrice: (data['female_price'] as num?)?.toDouble() ?? 0,
      duration: (data['duration'] as num?)?.toInt() ?? 45,
      category: data['category'] as String? ?? 'Hair',
    );
  }

  ChatLine _lineFrom(Map<String, dynamic> data, AppUser user) {
    final sender = data['sender_role'] as String? ?? 'system';
    return ChatLine(
      id: data['id'] as String,
      body: data['body'] as String? ?? '',
      senderRole: sender,
      mine: sender == user.role,
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earth = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earth * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double degrees) => degrees * pi / 180;

  String _newId(String prefix) {
    final hex = List.generate(4, (_) => Random.secure().nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$prefix$hex';
  }
}
