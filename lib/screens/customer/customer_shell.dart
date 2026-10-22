import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/salon_bottom_nav.dart';
import '../../services/face_analysis_service.dart';
import '../../services/recommendation_service.dart';
import '../ai_style_screen.dart';
import 'bookings_screen.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.state});

  final AppState state;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late final _analysis = FaceAnalysisService();
  late final _recommendations = RecommendationService();

  @override
  void initState() {
    super.initState();
    if (widget.state.salons.isEmpty && !widget.state.loading) {
      widget.state.loadCustomer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final pages = [
      HomeScreen(state: widget.state),
      BookingsScreen(state: widget.state),
      AiStyleScreen(
        analysisService: _analysis,
        recommendationService: _recommendations,
      ),
      ChatScreen(state: widget.state),
      ProfileScreen(state: widget.state),
    ];
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: palette.background,
          body: IndexedStack(index: widget.state.customerTab, children: pages),
          bottomNavigationBar: SalonBottomNav(
            currentIndex: widget.state.customerTab,
            onSelected: widget.state.openCustomerTab,
            destinations: [
              const SalonNavDestination(icon: Icons.home_outlined, label: 'Home'),
              const SalonNavDestination(icon: Icons.calendar_month_outlined, label: 'Bookings'),
              const SalonNavDestination(icon: Icons.auto_awesome, label: 'AI Style'),
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
