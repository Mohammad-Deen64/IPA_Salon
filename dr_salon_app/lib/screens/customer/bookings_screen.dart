import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final upcoming = state.visibleAppointments.where((item) => item.status == 'pending' || item.status == 'accepted').toList();
    final past = state.visibleAppointments.where((item) => item.status == 'completed' || item.status == 'cancelled').toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('My Bookings', style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            state.isSignedIn ? 'Track all your appointments' : 'Sign in from Profile to see your bookings',
            style: TextStyle(color: palette.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(context, '${state.visibleAppointments.length}', 'Total'),
              _stat(context, '${upcoming.length}', 'Upcoming'),
              _stat(context, '${past.length}', 'Done'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Upcoming Appointments', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (upcoming.isEmpty) Text('No upcoming appointments.', style: TextStyle(color: palette.muted)),
          ...upcoming.map((item) => _card(context, item)),
          const SizedBox(height: 16),
          Text('Past Appointments', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (past.isEmpty) Text('No past appointments.', style: TextStyle(color: palette.muted)),
          ...past.map((item) => _card(context, item)),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GlassCard(
          child: Column(
            children: [
              Text(value, style: TextStyle(color: palette.foreground, fontSize: 22, fontWeight: FontWeight.w700)),
              Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Appointment item) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.salonName, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700))),
                StatusChip(item.status),
              ],
            ),
            Text(item.serviceName, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 8),
            Text('${item.date}  •  ${item.time}', style: TextStyle(color: palette.muted, fontSize: 13)),
            if (item.duration > 0)
              Text('Salon time: ${item.duration} mins', style: TextStyle(color: palette.muted, fontSize: 13)),
            if (item.arriveBy != null)
              Text(
                item.waitMinutes != null && item.waitMinutes! > 0
                    ? 'Arrive by ${item.arriveBy}  •  ${item.waitMinutes} min wait'
                    : 'Arrive by ${item.arriveBy}',
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Text('PKR ${item.price.toStringAsFixed(0)}', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
            if (item.status == 'pending')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => state.setStatus(item.id, 'cancelled'),
                  child: const Text('Cancel booking', style: TextStyle(color: AppColors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
