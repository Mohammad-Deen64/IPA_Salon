import 'package:flutter/material.dart';

import '../../models/salon.dart';
import '../../services/booking_hours.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.state,
    required this.salon,
    required this.service,
    required this.gender,
  });

  final AppState state;
  final Salon salon;
  final SalonService service;
  final String gender;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay? _clock;
  String? _error;
  bool _saving = false;
  bool _loadingQueue = false;
  List<QueueBooking> _queue = const [];
  late final _name = TextEditingController(text: widget.state.customerName);

  String get _opens => widget.salon.opensAt;
  String get _closes => widget.salon.openUntil;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _time => _clock == null ? null : formatClock(_clock!.hour * 60 + _clock!.minute);

  ArrivalPreview? get _arrival {
    final time = _time;
    if (time == null) {
      return null;
    }
    return previewArrival(queue: _queue, requested: time, duration: widget.service.duration);
  }

  Future<void> _loadQueue() async {
    setState(() => _loadingQueue = true);
    try {
      final queue = await widget.state.salonQueue(widget.salon.id, _date);
      if (mounted) {
        setState(() => _queue = queue);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _queue = const []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingQueue = false);
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _clock ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppPalette.of(context).background,
              hourMinuteTextColor: AppPalette.of(context).foreground,
              dialHandColor: AppColors.purple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _clock = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final price = widget.service.priceFor(widget.gender);
    final arrival = _arrival;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Appointment'),
            Text(widget.salon.name, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Details', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _row(palette, 'Service', widget.service.name),
                _row(palette, 'Time this takes', '${widget.service.duration} mins'),
                _row(palette, 'Shop hours', '$_opens – $_closes'),
                _row(palette, 'Price', 'PKR ${price.toStringAsFixed(0)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: TextStyle(color: palette.foreground),
            decoration: InputDecoration(
              labelText: 'Your name',
              labelStyle: TextStyle(color: palette.muted),
              filled: true,
              fillColor: palette.input,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Date', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
          CalendarDatePicker(
            initialDate: _date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            onDateChanged: (value) {
              setState(() => _date = value);
              _loadQueue();
            },
          ),
          Text('Select Time', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Pick any time while the shop is open. You cannot book after $_closes.',
            style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(_time == null ? 'Choose your time' : _time!),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: palette.foreground,
              side: BorderSide(color: palette.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingQueue)
            Text('Checking the booking queue...', style: TextStyle(color: palette.muted, fontSize: 13))
          else if (arrival != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('When to arrive', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _row(palette, 'People ahead', '${arrival.ahead}'),
                  _row(palette, 'Wait from your time', arrival.waitMinutes == 0 ? 'No wait' : '${arrival.waitMinutes} mins'),
                  _row(palette, 'Arrive by', arrival.arriveBy),
                  _row(palette, 'Estimated finish', arrival.finishBy),
                  const SizedBox(height: 6),
                  Text(
                    arrival.waitMinutes == 0
                        ? 'The chair is free at your chosen time. The salon set this service at ${widget.service.duration} minutes.'
                        : 'Reach the shop by ${arrival.arriveBy}. The chair is finishing earlier bookings first.',
                    style: TextStyle(color: palette.muted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              child: Text(
                _queue.isEmpty
                    ? 'No one is booked on this date yet. Choose a time during shop hours.'
                    : '${_queue.length} booking${_queue.length == 1 ? '' : 's'} already on this date.',
                style: TextStyle(color: palette.muted, height: 1.4),
              ),
            ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _row(palette, 'Service Fee', 'PKR ${price.toStringAsFixed(0)}'),
                _row(palette, 'Booking Fee', 'PKR 2'),
                _row(palette, 'Total', 'PKR ${(price + 2).toStringAsFixed(0)}'),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          GradientButton(
            label: _saving ? 'Booking...' : 'Confirm Booking',
            onPressed: _saving ? null : _confirm,
          ),
        ],
      ),
    );
  }

  Widget _row(AppPalette palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: palette.muted)),
          const Spacer(),
          Text(value, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final time = _time;
    if (time == null) {
      setState(() => _error = 'Choose a time.');
      return;
    }
    if (!widget.state.isSignedIn) {
      setState(() => _error = 'Sign in from Profile to book.');
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    try {
      final requested = parseClock(time);
      final opens = parseClock(_opens);
      final closes = parseClock(_closes);
      if (requested < opens) {
        setState(() => _error = 'The shop opens at $_opens.');
        return;
      }
      if (requested >= closes) {
        setState(() => _error = 'You cannot book after the shop closes at $_closes.');
        return;
      }
      final arrival = previewArrival(queue: _queue, requested: time, duration: widget.service.duration);
      if (arrival.finishMinutes > closes) {
        setState(() => _error = 'There is not enough time to finish this service before $_closes.');
        return;
      }
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.state.updateProfile(name: _name.text.trim(), phone: widget.state.customerPhone);
      await widget.state.book(
        salon: widget.salon,
        service: widget.service,
        date: _date,
        time: time,
        gender: widget.gender,
      );
      if (!mounted) {
        return;
      }
      final arrival = _arrival;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppPalette.of(dialogContext).background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Booking confirmed'),
          content: Text(
            arrival == null
                ? 'Your appointment is pending the salon.'
                : 'Arrive by ${arrival.arriveBy}. This ${widget.service.name.toLowerCase()} takes ${widget.service.duration} minutes.',
            style: TextStyle(color: AppPalette.of(dialogContext).muted, height: 1.4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
