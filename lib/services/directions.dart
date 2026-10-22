import 'package:url_launcher/url_launcher.dart';

Future<bool> openSalonDirections({
  double? fromLat,
  double? fromLng,
  double? lat,
  double? lng,
  String? name,
  String? address,
}) async {
  final destination = lat != null && lng != null
      ? '$lat,$lng'
      : Uri.encodeComponent([name, address].where((item) => item != null && item.isNotEmpty).join(', '));
  if (destination.isEmpty) {
    return false;
  }
  final origin = fromLat != null && fromLng != null ? '&origin=$fromLat,$fromLng' : '';
  final query = lat != null && lng != null ? '$lat,$lng' : destination;
  final uris = <Uri>[
    if (lat != null && lng != null)
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination$origin&travelmode=driving'),
    if (lat != null && lng != null) Uri.parse('google.navigation:q=$lat,$lng&mode=d'),
    if (lat != null && lng != null) Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(name ?? 'Salon')})'),
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
  ];
  for (final uri in uris) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}
  }
  return false;
}
