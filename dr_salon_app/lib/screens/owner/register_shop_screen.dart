import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/gmail.dart';
import '../../widgets/style.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key, required this.state});

  final AppState state;

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final _shop = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _prices = {
    for (final name in const ['Haircut', 'Beard', 'Massage', 'Facial']) name: TextEditingController(),
  };
  final _selected = <String>{'Haircut'};
  double? _lat;
  double? _lng;
  File? _photo;
  bool _busy = false;
  bool _waitingForGmail = false;
  String? _message;

  @override
  void dispose() {
    _shop.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    for (final controller in _prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Register your shop')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Your shop is saved after Gmail verification.', style: TextStyle(color: palette.muted)),
            const SizedBox(height: 16),
            _field(palette, 'Shop name', _shop),
            _field(palette, 'Shop location', _address),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _busy ? null : _useLocation, child: const Text('Use my location')),
            ),
            if (_lat != null)
              Text('Location saved', style: TextStyle(color: palette.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Specialities and price', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final name in _prices.keys) _speciality(palette, name),
            const SizedBox(height: 8),
            _field(palette, 'Phone number', _phone),
            _field(palette, 'Gmail', _email),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(gmailFormatHint, style: TextStyle(color: palette.muted, fontSize: 12)),
            ),
            _field(palette, 'Password', _password, obscure: true),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_photo == null ? 'Shop profile photo' : 'Photo selected'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: TextStyle(color: _waitingForGmail ? AppColors.green : AppColors.red)),
            ],
            const SizedBox(height: 16),
            GradientButton(
              label: _busy ? 'Please wait...' : (_waitingForGmail ? 'I verified my Gmail' : 'Register shop'),
              onPressed: _busy ? null : (_waitingForGmail ? _confirm : _submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speciality(AppPalette palette, String name) {
    final on = _selected.contains(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: on,
            activeColor: AppColors.purple,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(name);
                      } else {
                        _selected.remove(name);
                      }
                    });
                  },
          ),
          SizedBox(width: 90, child: Text(name, style: TextStyle(color: palette.foreground))),
          Expanded(child: _field(palette, 'Price', _prices[name]!, enabled: on)),
        ],
      ),
    );
  }

  Widget _field(AppPalette palette, String label, TextEditingController controller, {bool obscure = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled && !_busy,
        obscureText: obscure,
        keyboardType: label == 'Price' || label == 'Phone number' ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: palette.foreground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: palette.muted),
          filled: true,
          fillColor: palette.input,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Future<void> _useLocation() async {
    final location = await LocationService().current();
    if (!mounted) {
      return;
    }
    setState(() {
      _lat = location.latitude;
      _lng = location.longitude;
      _message = location.usedGps ? null : location.message;
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 45);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    final services = <Map<String, dynamic>>[];
    for (final name in _selected) {
      final price = double.tryParse(_prices[name]!.text.trim());
      if (price == null || price <= 0) {
        setState(() => _message = 'Enter a price for $name.');
        return;
      }
      services.add({'name': name, 'price': price});
    }
    if (!isGmailAddress(_email.text)) {
      setState(() => _message = gmailFormatError);
      return;
    }
    if (services.isEmpty || _lat == null || _lng == null || _photo == null) {
      setState(() => _message = 'Add a photo, your location, and at least one priced speciality.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final encoded = base64Encode(await _photo!.readAsBytes());
      final result = await widget.state.registerShop(
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        shopName: _shop.text.trim(),
        address: _address.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        imageBase64: encoded,
        services: services,
      );
      if (!mounted) {
        return;
      }
      if (result.verified) {
        await widget.state.confirmShopEmail(_email.text.trim(), _password.text);
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      setState(() {
        _waitingForGmail = true;
        _message = 'Open your Gmail, tap the verification link, then continue.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.state.confirmShopEmail(_email.text.trim(), _password.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
