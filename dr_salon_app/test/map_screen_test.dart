import 'package:dr_salon_app/models/salon.dart';
import 'package:dr_salon_app/screens/customer/map_screen.dart';
import 'package:dr_salon_app/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map shows OpenStreetMap and salon markers from backend data', (tester) async {
    final state = AppState()
      ..salons = const [
        Salon(
          id: '1',
          name: 'Elegance Studio',
          rating: 4.8,
          distance: '1.2 km',
          startingPrice: 25,
          image: '',
          location: 'F-7 Markaz, Islamabad',
          description: '[Demo]',
          phone: '123',
          email: 'salon@example.com',
          openUntil: '9 PM',
          tags: ['Demo'],
          availableSlots: ['2:00 PM'],
          services: [],
          latitude: 33.7215,
          longitude: 73.0578,
        ),
      ];
    await tester.pumpWidget(MaterialApp(home: MapScreen(state: state)));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Elegance Studio'), findsOneWidget);
    expect(find.text('Salon map'), findsOneWidget);
  });
}
