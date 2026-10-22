import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/salon_bottom_nav.dart';
import '../customer/chat_screen.dart';
import 'appointments_screen.dart';
import 'dashboard_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key, required this.state});

  final AppState state;

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.state.isSignedIn && widget.state.stats == null && !widget.state.loading) {
      widget.state.loadOwner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final pages = [
      DashboardScreen(state: widget.state),
      AppointmentsScreen(state: widget.state),
      ServicesScreen(state: widget.state),
      ChatScreen(state: widget.state),
      SettingsScreen(state: widget.state),
    ];
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: palette.background,
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: SalonBottomNav(
            currentIndex: _index,
            onSelected: (index) => setState(() => _index = index),
            destinations: [
              const SalonNavDestination(icon: Icons.dashboard_outlined, label: 'Dashboard'),
              const SalonNavDestination(icon: Icons.calendar_month_outlined, label: 'Appointments'),
              const SalonNavDestination(icon: Icons.content_cut, label: 'Services'),
              SalonNavDestination(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                badge: widget.state.chatCount > 0 ? widget.state.chatCount : null,
              ),
              const SalonNavDestination(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
