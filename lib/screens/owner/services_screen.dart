import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
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
                    Text('Services & Pricing', style: TextStyle(color: palette.foreground, fontSize: 22, fontWeight: FontWeight.w700)),
                    Text('Set the time you take for each service', style: TextStyle(color: palette.muted)),
                  ],
                ),
              ),
              if (state.isSignedIn) TextButton(onPressed: () => _edit(context), child: const Text('Add Service')),
            ],
          ),
          const SizedBox(height: 12),
          if (!state.isSignedIn)
            Text('Sign in from Profile to manage services.', style: TextStyle(color: palette.muted))
          else if (state.ownerServices.isEmpty)
            Text('No services yet.', style: TextStyle(color: palette.muted)),
          ...state.ownerServices.map((service) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () => _edit(context, service),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(service.name, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700))),
                          IconButton(onPressed: () => state.removeService(service.id), icon: const Icon(Icons.delete_outline, color: AppColors.red)),
                        ],
                      ),
                      Text('Male PKR ${service.malePrice.toStringAsFixed(0)}  •  Female PKR ${service.femalePrice.toStringAsFixed(0)}', style: TextStyle(color: palette.muted)),
                      Text('You take ${service.duration} minutes  •  ${service.category}', style: TextStyle(color: palette.muted, fontSize: 13)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, [SalonService? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final male = TextEditingController(text: existing?.malePrice.toStringAsFixed(0) ?? '25');
    final female = TextEditingController(text: existing?.femalePrice.toStringAsFixed(0) ?? '35');
    final duration = TextEditingController(text: existing?.duration.toString() ?? '45');
    final category = TextEditingController(text: existing?.category ?? 'Hair');
    const presets = [
      ('Haircut', 45, 'Hair'),
      ('Beard', 20, 'Beard'),
      ('Facial', 60, 'Facial'),
      ('Makeup', 90, 'Makeup'),
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = AppPalette.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setSheet) {
            return AlertDialog(
              backgroundColor: palette.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(existing == null ? 'Add Service' : 'Edit Service', style: TextStyle(color: palette.foreground)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(palette, name, 'Service name'),
                    _field(palette, male, 'Male price'),
                    _field(palette, female, 'Female price'),
                    Text('How long you take', style: TextStyle(color: palette.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets
                          .map(
                            (item) => ChoiceChip(
                              label: Text('${item.$1} ${item.$2}m'),
                              selected: duration.text == '${item.$2}',
                              onSelected: (_) => setSheet(() {
                                duration.text = '${item.$2}';
                                category.text = item.$3;
                                if (name.text.trim().isEmpty) {
                                  name.text = item.$1;
                                }
                              }),
                              selectedColor: AppColors.purple,
                              labelStyle: TextStyle(color: duration.text == '${item.$2}' ? Colors.white : palette.muted),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _field(palette, duration, 'Minutes you take'),
                    _field(palette, category, 'Category'),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    final minutes = int.tryParse(duration.text) ?? 0;
                    if (minutes < 5 || minutes > 300) {
                      return;
                    }
                    final payload = {
                      'name': name.text,
                      'male_price': double.tryParse(male.text) ?? 0,
                      'female_price': double.tryParse(female.text) ?? 0,
                      'duration': minutes,
                      'category': category.text,
                    };
                    if (existing == null) {
                      await state.addService(payload);
                    } else {
                      await state.editService(existing.id, payload);
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _field(AppPalette palette, TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: palette.foreground),
        keyboardType: label.contains('price') || label.contains('Minutes') ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: palette.muted),
        ),
      ),
    );
  }
}
