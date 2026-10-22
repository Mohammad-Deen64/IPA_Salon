import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../services/directions.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';
import 'booking_screen.dart';

class SalonDetailsScreen extends StatefulWidget {
  const SalonDetailsScreen({super.key, required this.state, required this.salon});

  final AppState state;
  final Salon salon;

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  String _gender = 'male';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final salon = widget.salon;
    final categories = ['All', ...{for (final item in salon.services) item.category}];
    final services = salon.services.where((item) => _category == 'All' || item.category == _category).toList();
    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        children: [
          Stack(
            children: [
              Image.network(
                salon.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(height: 220, color: const Color(0xFF1D233A)),
              ),
              Positioned(
                left: 12,
                top: 40,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(salon.name, style: TextStyle(color: palette.foreground, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(salon.description, style: TextStyle(color: palette.muted)),
                const SizedBox(height: 8),
                Text('${salon.rating}  •  ${salon.distance}  •  ${salon.location}', style: TextStyle(color: palette.muted, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${salon.phone}  •  Open ${salon.opensAt} – ${salon.openUntil}', style: TextStyle(color: palette.muted, fontSize: 13)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => openSalonDirections(
                    fromLat: widget.state.userLatitude,
                    fromLng: widget.state.userLongitude,
                    lat: salon.latitude,
                    lng: salon.longitude,
                    name: salon.name,
                    address: salon.location,
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _genderChip('male', 'Male'),
                    const SizedBox(width: 8),
                    _genderChip('female', 'Female'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Services & Pricing', style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: categories
                      .map((item) => ChoiceChip(
                            label: Text(item),
                            selected: _category == item,
                            onSelected: (_) => setState(() => _category = item),
                            selectedColor: AppColors.purple,
                            labelStyle: TextStyle(color: _category == item ? Colors.white : palette.muted),
                            backgroundColor: palette.card,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (services.isEmpty) Text('No services in this category.', style: TextStyle(color: palette.muted)),
                ...services.map((service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(service.name, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700))),
                                Text('PKR ${service.priceFor(_gender).toStringAsFixed(0)}', style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Text('Salon time: ${service.duration} mins', style: TextStyle(color: palette.muted)),
                            const SizedBox(height: 10),
                            GradientButton(
                              label: 'Book Now',
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => BookingScreen(state: widget.state, salon: salon, service: service, gender: _gender),
                                ));
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
                Text('Shop hours', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Book any time from ${salon.opensAt} to ${salon.openUntil}. The owner sets how long each service takes.',
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String value, String label) {
    final palette = AppPalette.of(context);
    final active = _gender == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: active,
        onSelected: (_) => setState(() => _gender = value),
        selectedColor: AppColors.purple,
        labelStyle: TextStyle(color: active ? Colors.white : palette.muted),
        backgroundColor: palette.card,
      ),
    );
  }
}
