import 'package:dr_salon_app/models/appointment.dart';
import 'package:dr_salon_app/models/salon.dart';
import 'package:dr_salon_app/screens/customer/bookings_screen.dart';
import 'package:dr_salon_app/screens/customer/home_screen.dart';
import 'package:dr_salon_app/screens/customer/profile_screen.dart';
import 'package:dr_salon_app/screens/role_screen.dart';
import 'package:dr_salon_app/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('role screen offers customer and owner without an API field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RoleScreen(state: AppState())));
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Salon Owner'), findsOneWidget);
    expect(find.text('API server'), findsNothing);
    expect(find.textContaining('http://'), findsNothing);
  });

  testWidgets('customer profile offers sign in and create account when signed out', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileScreen(state: AppState()))));
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('API server'), findsNothing);
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('API server'), findsNothing);
  });

  testWidgets('home lists salons and opens AI from the banner', (tester) async {
    final state = AppState()..salons = [_salon];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HomeScreen(state: state))));
    expect(find.text('Salons'), findsOneWidget);
    expect(find.text('Nearby Salons'), findsNothing);
    expect(find.text('Elegance Studio'), findsOneWidget);
    await tester.tap(find.text('Try Now'));
    await tester.pump();
    expect(state.customerTab, 2);
  });

  testWidgets('bookings shows upcoming appointments and cancel', (tester) async {
    final state = AppState()..appointments = [_appointment];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BookingsScreen(state: state))));
    expect(find.text('Elegance Studio'), findsOneWidget);
    expect(find.text('Cancel booking'), findsOneWidget);
  });
}

const _salon = Salon(
  id: '1',
  name: 'Elegance Studio',
  rating: 4.8,
  distance: '1.2 km',
  startingPrice: 25,
  image: '',
  location: 'Downtown',
  description: 'Premium salon',
  phone: '123',
  email: 'salon@example.com',
  openUntil: '9 PM',
  tags: ['Premium'],
  availableSlots: ['2:00 PM'],
  services: [
    SalonService(id: 's1', name: 'Haircut', malePrice: 25, femalePrice: 35, duration: 45, category: 'Hair'),
  ],
);

const _appointment = Appointment(
  id: 'a1',
  salonId: '1',
  salonName: 'Elegance Studio',
  serviceName: 'Haircut',
  date: '2026-01-05',
  time: '2:00 PM',
  price: 27,
  status: 'pending',
  customerName: 'Ahmed',
  customerPhone: '123',
);
