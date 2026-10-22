import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final stats = state.stats;
    final salonName = state.ownerProfile?.name ?? 'Your salon';
    final ownerName = state.ownerProfile?.ownerName ?? state.customerName;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text('Dashboard', style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 6),
          Text(
            state.isSignedIn ? 'Welcome back${ownerName.isEmpty ? '' : ', $ownerName'}' : 'Sign in from Profile to see bookings and earnings',
            style: TextStyle(color: palette.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          if (state.error != null) Text(state.error!, style: const TextStyle(color: AppColors.red)),
          if (state.loading) const Center(child: CircularProgressIndicator(color: AppColors.purple)),
          if (!state.isSignedIn)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: Text('Sign in to see this week\'s bookings and the money you earned.', textAlign: TextAlign.center, style: TextStyle(color: palette.muted, height: 1.4)),
            )
          else if (stats != null) ...[
            _hero(palette, salonName, stats),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(palette, Icons.calendar_today_outlined, AppColors.purple, '${stats.todayBookings}', "Today's bookings"),
                const SizedBox(width: 10),
                _stat(palette, Icons.hourglass_empty, AppColors.gold, '${stats.pending}', 'Pending'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(palette, Icons.check_circle_outline, AppColors.green, '${stats.completed}', 'Completed'),
                const SizedBox(width: 10),
                _stat(palette, Icons.payments_outlined, AppColors.violet, 'PKR ${stats.revenue.toStringAsFixed(0)}', 'All-time earned'),
              ],
            ),
            const SizedBox(height: 18),
            _chartCard(
              palette,
              title: 'Bookings this week',
              subtitle: '${stats.weekTotal} appointments',
              child: _WeekChart(days: stats.daily, mode: _ChartMode.bookings, accent: AppColors.purple),
            ),
            const SizedBox(height: 12),
            _chartCard(
              palette,
              title: 'Money earned this week',
              subtitle: 'PKR ${stats.weekRevenue.toStringAsFixed(0)} from completed bookings',
              child: _WeekChart(days: stats.daily, mode: _ChartMode.revenue, accent: AppColors.gold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.star_rounded, color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stats.rating.toStringAsFixed(1)} salon rating', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                        Text('${stats.reviewCount} reviews', style: TextStyle(color: palette.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!state.loading)
            Text('No dashboard data yet.', style: TextStyle(color: palette.muted)),
        ],
      ),
    );
  }

  Widget _hero(AppPalette palette, String salonName, OwnerStats stats) {
    final todayEarn = stats.daily.isEmpty ? 0.0 : stats.daily.last.revenue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.32), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(salonName, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Earned today', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text('PKR ${todayEarn.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 6),
          Text('${stats.todayBookings} booking${stats.todayBookings == 1 ? '' : 's'} today', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stat(AppPalette palette, IconData icon, Color color, String value, String label) {
    return Expanded(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: palette.foreground, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(AppPalette palette, {required String title, required String subtitle, required Widget child}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(height: 176, child: child),
        ],
      ),
    );
  }
}

enum _ChartMode { bookings, revenue }

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days, required this.mode, required this.accent});

  final List<DayStat> days;
  final _ChartMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final series = days.isEmpty
        ? List<DayStat>.generate(7, (index) => DayStat(date: '', label: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index], bookings: 0, revenue: 0))
        : days;
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _WeekChartPainter(days: series, mode: mode, accent: accent, axis: palette.muted.withValues(alpha: 0.35)),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final day in series)
              Expanded(
                child: Text(day.label, textAlign: TextAlign.center, style: TextStyle(color: palette.muted, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekChartPainter extends CustomPainter {
  _WeekChartPainter({required this.days, required this.mode, required this.accent, required this.axis});

  final List<DayStat> days;
  final _ChartMode mode;
  final Color accent;
  final Color axis;

  double _value(DayStat day) => mode == _ChartMode.bookings ? day.bookings.toDouble() : day.revenue;

  @override
  void paint(Canvas canvas, Size size) {
    final values = days.map(_value).toList();
    final maxValue = values.fold<double>(0, math.max);
    final top = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final barWidth = size.width / (days.length * 2.1);
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.38), accent.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);
    final grid = Paint()
      ..color = axis
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset point(int index) {
      final x = (index + 0.5) * (size.width / days.length);
      final y = size.height - (values[index] / top) * size.height;
      return Offset(x, y.clamp(4, size.height - 2));
    }

    if (mode == _ChartMode.bookings) {
      for (var index = 0; index < days.length; index++) {
        final x = (index + 0.5) * (size.width / days.length);
        final height = (values[index] / top) * size.height;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, size.height - height, barWidth, math.max(height, 3)),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, AppColors.violet],
            ).createShader(rect.outerRect),
        );
      }
      return;
    }

    if (days.length < 2) {
      return;
    }
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < days.length; index++) {
      final previous = point(index - 1);
      final current = point(index);
      final mid = Offset((previous.dx + current.dx) / 2, (previous.dy + current.dy) / 2);
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(point(days.length - 1).dx, point(days.length - 1).dy);
    canvas.drawPath(path, linePaint);
    final area = Path.from(path)
      ..lineTo(point(days.length - 1).dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();
    canvas.drawPath(area, fill);
    for (var index = 0; index < days.length; index++) {
      canvas.drawCircle(point(index), 4, Paint()..color = accent);
      canvas.drawCircle(point(index), 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekChartPainter oldDelegate) {
    return oldDelegate.days != days || oldDelegate.mode != mode || oldDelegate.accent != accent;
  }
}
