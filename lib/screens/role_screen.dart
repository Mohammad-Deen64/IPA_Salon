import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/App logo.jpg', width: 96, height: 96, fit: BoxFit.contain),
              const SizedBox(height: 16),
              Text('Dr Salon', style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Choose Your Role', style: TextStyle(color: palette.foreground, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Continue as', style: TextStyle(color: palette.muted)),
              const SizedBox(height: 28),
              _card(
                palette,
                'Customer',
                'Book appointments and explore styles',
                Icons.person_outline,
                AppColors.purple,
                () => state.chooseRole(UserRole.customer),
              ),
              const SizedBox(height: 14),
              _card(
                palette,
                'Salon Owner',
                'Manage bookings and your salon',
                Icons.storefront_outlined,
                AppColors.gold,
                () => state.chooseRole(UserRole.owner),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    AppPalette palette,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Continue', style: TextStyle(color: palette.foreground, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
