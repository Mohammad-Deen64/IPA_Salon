import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/customer/customer_shell.dart';
import 'screens/owner/owner_shell.dart';
import 'screens/role_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final state = AppState();
  await state.restoreLocal();
  runApp(DrSalonApp(state: state));
}

class DrSalonApp extends StatefulWidget {
  const DrSalonApp({super.key, required this.state});

  final AppState state;

  @override
  State<DrSalonApp> createState() => _DrSalonAppState();
}

class _DrSalonAppState extends State<DrSalonApp> {
  late final AppState _state = widget.state;

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_state.role == UserRole.owner) {
      home = OwnerShell(state: _state);
    } else if (_state.role == UserRole.customer) {
      home = CustomerShell(state: _state);
    } else {
      home = RoleScreen(state: _state);
    }
    return MaterialApp(
      title: 'Dr Salon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _state.darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: home,
    );
  }
}
