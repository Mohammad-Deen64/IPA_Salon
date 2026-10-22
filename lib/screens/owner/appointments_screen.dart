import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';
import '../customer/chat_thread_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _tab = 'pending';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final items = widget.state.appointments.where((item) => item.status == _tab).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Appointments', style: TextStyle(color: palette.foreground, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(
            widget.state.isSignedIn ? 'Manage your booking requests' : 'Sign in from Profile to manage bookings',
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['pending', 'accepted', 'rejected', 'completed', 'cancelled'].map((item) {
              final active = _tab == item;
              return ChoiceChip(
                label: Text(item[0].toUpperCase() + item.substring(1)),
                selected: active,
                onSelected: (_) => setState(() => _tab = item),
                selectedColor: AppColors.purple,
                labelStyle: TextStyle(color: active ? Colors.white : palette.muted),
                backgroundColor: palette.card,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty) Text('No $_tab appointments.', style: TextStyle(color: palette.muted)),
          ...items.map(_card),
        ],
      ),
    );
  }

  Widget _card(Appointment item) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.customerName, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700))),
                StatusChip(item.status),
              ],
            ),
            Text(item.serviceName, style: TextStyle(color: palette.muted)),
            Text(
              item.duration > 0 ? '${item.date}  •  ${item.time}  •  ${item.duration} mins' : '${item.date}  •  ${item.time}',
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
            Text(item.customerPhone, style: TextStyle(color: palette.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Text('PKR ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.deepPurple, fontWeight: FontWeight.w700)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final salonId = widget.state.ownerProfile?.id;
                  if (salonId == null || item.customerId.isEmpty) {
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      state: widget.state,
                      salonId: salonId,
                      customerId: item.customerId,
                      title: item.customerName,
                    ),
                  ));
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Message'),
              ),
            ),
            if (item.status == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(onPressed: () => widget.state.setStatus(item.id, 'rejected'), child: const Text('Reject', style: TextStyle(color: AppColors.red))),
                  const Spacer(),
                  TextButton(onPressed: () => widget.state.setStatus(item.id, 'accepted'), child: const Text('Accept', style: TextStyle(color: AppColors.green))),
                ],
              ),
            ],
            if (item.status == 'accepted') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.state.setStatus(item.id, 'completed'),
                  child: const Text('Mark complete', style: TextStyle(color: AppColors.green)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
