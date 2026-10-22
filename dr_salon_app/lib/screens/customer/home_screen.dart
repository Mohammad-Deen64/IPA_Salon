import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';
import 'map_screen.dart';
import 'salon_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 18 ? 'Good Afternoon' : 'Good Evening';
    final salons = widget.state.salons.where((salon) {
      final matchQuery = _query.isEmpty ||
          salon.name.toLowerCase().contains(_query.toLowerCase()) ||
          salon.location.toLowerCase().contains(_query.toLowerCase());
      final matchCategory = _category == 'All' ||
          salon.services.any((item) =>
              item.category.toLowerCase().contains(_category.toLowerCase()) ||
              item.name.toLowerCase().contains(_category.toLowerCase()));
      return matchQuery && matchCategory;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(color: palette.muted)),
                    Text(
                      widget.state.customerName.isEmpty ? 'Guest' : widget.state.customerName,
                      style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.state.openCustomerTab(4),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF1D233A),
                    child: Text(
                      widget.state.customerName.isEmpty ? 'G' : widget.state.customerName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.purple, size: 16),
              const SizedBox(width: 6),
              Text('Islamabad, Pakistan', style: TextStyle(color: palette.muted)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: TextStyle(color: palette.foreground),
            decoration: InputDecoration(
              hintText: 'Search salons, services...',
              hintStyle: TextStyle(color: palette.muted),
              prefixIcon: Icon(Icons.search, color: palette.muted),
              filled: true,
              fillColor: palette.input,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Haircut', 'Facial', 'Makeup', 'Beard'].map((item) {
                final active = _category == item;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: active,
                    onSelected: (_) => setState(() => _category = item),
                    selectedColor: AppColors.purple,
                    labelStyle: TextStyle(color: active ? Colors.white : palette.muted),
                    backgroundColor: palette.card,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            onTap: () => widget.state.openCustomerTab(2),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Style Finder', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                      Text('Upload a photo and get styles', style: TextStyle(color: palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Try Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.state.locationEnabled ? 'Nearby Salons' : 'Salons',
                  style: TextStyle(color: palette.foreground, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapScreen(state: widget.state)));
                },
                child: const Text('Map'),
              ),
            ],
          ),
          if (widget.state.locationMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.state.locationMessage!, style: TextStyle(color: palette.muted, fontSize: 12)),
            ),
          if (!widget.state.locationEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => widget.state.retryLocation(), child: const Text('Use my location')),
            ),
          if (widget.state.locationEnabled && widget.state.salons.isNotEmpty) ...[
            Text('Suggested for you', style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.state.salons.take(3).map(_suggestionCard).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          if (widget.state.error != null) Text(widget.state.error!, style: const TextStyle(color: AppColors.red)),
          if (widget.state.loading) const Center(child: CircularProgressIndicator(color: AppColors.purple)),
          if (!widget.state.loading && salons.isEmpty)
            Text('No salons match your search.', style: TextStyle(color: palette.muted)),
          ...salons.map(_salonCard),
        ],
      ),
    );
  }

  Widget _suggestionCard(Salon salon) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _openDetails(salon),
        child: Container(
          width: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                salon.imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 110,
                  color: palette.input,
                  alignment: Alignment.center,
                  child: Icon(Icons.storefront_outlined, color: palette.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(salon.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(salon.distance, style: const TextStyle(color: AppColors.purple, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                salon.tags.where((tag) => tag != 'Demo').take(3).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _salonCard(Salon salon) {
    final palette = AppPalette.of(context);
    final saved = widget.state.savedSalonIds.contains(salon.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () => _openDetails(salon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                    Image.network(
                    salon.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(height: 160, color: const Color(0xFF1D233A)),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
                      child: Text('${salon.opensAt} – ${salon.openUntil}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () => widget.state.toggleSaved(salon.id),
                      child: CircleAvatar(
                        backgroundColor: saved ? AppColors.red.withValues(alpha: 0.9) : Colors.white24,
                        child: Icon(saved ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(salon.name, style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: salon.tags
                        .map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                              labelStyle: const TextStyle(color: AppColors.purple),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                      Text(' ${salon.rating}  •  ${salon.distance}', style: TextStyle(color: palette.muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('PKR ${salon.startingPrice.toStringAsFixed(0)}', style: TextStyle(color: palette.foreground, fontSize: 24, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openDetails(salon),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(Salon salon) {
    widget.state.selectedSalon = salon;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalonDetailsScreen(state: widget.state, salon: salon)));
  }
}
