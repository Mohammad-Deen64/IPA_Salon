import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/salon.dart';
import '../../services/directions.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import 'salon_details_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final markers = state.salons.where((salon) => salon.latitude != null && salon.longitude != null).toList();
    final center = state.userLatitude != null && state.userLongitude != null
        ? LatLng(state.userLatitude!, state.userLongitude!)
        : markers.isNotEmpty
            ? LatLng(markers.first.latitude!, markers.first.longitude!)
            : const LatLng(33.6844, 73.0479);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(state.locationEnabled ? 'Nearby salons' : 'Salon map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              state.locationMessage ?? 'Tap a salon pin, then open Directions to follow the route in Maps.',
              style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.example.dr_salon_app',
                      maxNativeZoom: 19,
                    ),
                    const SimpleAttributionWidget(source: Text('Esri / OpenStreetMap')),
                    MarkerLayer(
                      markers: [
                        if (state.userLatitude != null && state.userLongitude != null)
                          Marker(
                            point: LatLng(state.userLatitude!, state.userLongitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Color(0xFF38BDF8), size: 28),
                          ),
                        for (final salon in markers)
                          Marker(
                            point: LatLng(salon.latitude!, salon.longitude!),
                            width: 150,
                            height: 68,
                            child: GestureDetector(
                              onTap: () => _choose(context, salon),
                              child: Column(
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.purple, size: 32),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: palette.card,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: palette.border),
                                    ),
                                    child: Text(
                                      salon.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: palette.foreground, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (markers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () => _directions(markers.first),
                icon: const Icon(Icons.directions),
                label: const Text('Directions to nearest salon'),
              ),
            ),
        ],
      ),
    );
  }

  void _choose(BuildContext context, Salon salon) {
    final host = context;
    final palette = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(salon.name, style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(salon.location, style: TextStyle(color: palette.muted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _directions(salon);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _open(host, salon);
                      },
                      child: const Text('View salon'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _directions(Salon salon) async {
    await openSalonDirections(
      fromLat: state.userLatitude,
      fromLng: state.userLongitude,
      lat: salon.latitude,
      lng: salon.longitude,
      name: salon.name,
      address: salon.location,
    );
  }

  void _open(BuildContext context, Salon salon) {
    state.selectedSalon = salon;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalonDetailsScreen(state: state, salon: salon)));
  }
}
