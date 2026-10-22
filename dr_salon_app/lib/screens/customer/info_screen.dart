import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(body, style: TextStyle(color: palette.muted, height: 1.5)),
        ],
      ),
    );
  }
}
