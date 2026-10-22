import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';
import '../auth_screen.dart';
import 'register_shop_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _name = TextEditingController(text: widget.state.ownerProfile?.ownerName ?? widget.state.customerName);
  late final _salon = TextEditingController(text: widget.state.ownerProfile?.name ?? '');
  late final _description = TextEditingController(text: widget.state.ownerProfile?.description ?? '');
  late final _address = TextEditingController(text: widget.state.ownerProfile?.location ?? '');
  late final _phone = TextEditingController(text: widget.state.ownerProfile?.phone ?? '');
  late final _email = TextEditingController(text: widget.state.ownerProfile?.email ?? '');
  late final _opens = TextEditingController(text: widget.state.ownerProfile?.opensAt ?? '9 AM');
  late final _closes = TextEditingController(text: widget.state.ownerProfile?.openUntil ?? '9 PM');
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _message;
  String? _passwordMessage;

  @override
  void dispose() {
    _name.dispose();
    _salon.dispose();
    _description.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _opens.dispose();
    _closes.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _fill() {
    _name.text = widget.state.ownerProfile?.ownerName ?? widget.state.customerName;
    _salon.text = widget.state.ownerProfile?.name ?? '';
    _description.text = widget.state.ownerProfile?.description ?? '';
    _address.text = widget.state.ownerProfile?.location ?? '';
    _phone.text = widget.state.ownerProfile?.phone ?? '';
    _email.text = widget.state.ownerProfile?.email ?? '';
    _opens.text = widget.state.ownerProfile?.opensAt ?? '9 AM';
    _closes.text = widget.state.ownerProfile?.openUntil ?? '9 PM';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final signedIn = widget.state.isSignedIn;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text('Profile', style: TextStyle(color: palette.foreground, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(
            signedIn ? 'Your salon profile and account settings' : 'Sign in with email and password to manage your salon',
            style: TextStyle(color: palette.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          if (!signedIn) ...[
            GradientButton(
              label: 'Register your shop',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterShopScreen(state: widget.state)));
              },
            ),
            const SizedBox(height: 10),
            GradientButton(label: 'Sign In', onPressed: () => _openAuth(signup: false)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _openAuth(signup: true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.purple,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create account'),
            ),
          ] else ...[
            _coverCard(palette),
            const SizedBox(height: 16),
            if (_editing) ...[
              Text('Manage salon info', style: TextStyle(color: palette.foreground, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  children: [
                    _field(palette, 'Owner name', _name),
                    _field(palette, 'Salon name', _salon),
                    _field(palette, 'Description', _description, lines: 3),
                    _field(palette, 'Address', _address),
                    _field(palette, 'Phone number', _phone, keyboard: TextInputType.phone),
                    _field(palette, 'Email', _email, keyboard: TextInputType.emailAddress),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(label: _saving ? 'Saving...' : 'Save changes', onPressed: _saving ? null : _save),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _editing = false;
                          _fill();
                        }),
                child: const Text('Cancel'),
              ),
            ] else
              GradientButton(
                label: 'Edit profile',
                onPressed: () => setState(() {
                  _fill();
                  _editing = true;
                  _message = null;
                }),
              ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!, style: TextStyle(color: _message == 'Profile saved.' ? AppColors.green : AppColors.red)),
            ],
            const SizedBox(height: 24),
            Text('Settings', style: TextStyle(color: palette.foreground, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Change the password used to sign in.', style: TextStyle(color: palette.muted, fontSize: 12, height: 1.35)),
                  const SizedBox(height: 12),
                  _field(palette, 'Current password', _currentPassword, obscure: true),
                  _field(palette, 'New password', _newPassword, obscure: true),
                  _field(palette, 'Confirm new password', _confirmPassword, obscure: true),
                  if (_passwordMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _passwordMessage!,
                        style: TextStyle(color: _passwordMessage == 'Password updated.' ? AppColors.green : AppColors.red, fontSize: 13),
                      ),
                    ),
                  GradientButton(label: _saving ? 'Saving...' : 'Update password', onPressed: _saving ? null : _savePassword),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: widget.state.notificationsEnabled,
                onChanged: (value) => setState(() => widget.state.setNotifications(value)),
                title: Text('Notifications from customers', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  widget.state.notificationsEnabled ? 'Booking and chat alerts are on' : 'Customer alerts are off',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                activeThumbColor: AppColors.purple,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: widget.state.darkMode,
                onChanged: (_) => setState(() => widget.state.toggleTheme()),
                title: Text('Dark Mode', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
                activeThumbColor: AppColors.purple,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => widget.state.signOut(),
              icon: const Icon(Icons.logout, color: AppColors.red),
              label: const Text('Sign out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0x88EF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            TextButton(
              onPressed: _deleteAccount,
              child: const Text('Delete account', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverCard(AppPalette palette) {
    final salon = widget.state.ownerProfile;
    final cover = salon?.imageUrl;
    final ownerPhoto = salon?.ownerImageUrl ?? widget.state.user?.avatarUrl;
    final ownerName = salon?.ownerName ?? widget.state.customerName;
    final salonName = salon?.name ?? 'Your salon';
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: cover != null && cover.isNotEmpty
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _coverPlaceholder(palette),
                        )
                      : _coverPlaceholder(palette),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _photoButton(
                  label: 'Shop cover',
                  onTap: _saving ? null : () => _pickPhoto(cover: true),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 0,
                child: GestureDetector(
                  onTap: _saving ? null : () => _pickPhoto(cover: false),
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradient,
                          border: Border.all(color: palette.background, width: 3),
                        ),
                        child: CircleAvatar(
                          backgroundColor: palette.background,
                          backgroundImage: ownerPhoto == null ? null : NetworkImage(ownerPhoto),
                          child: ownerPhoto == null
                              ? Text(
                                  ownerName.isEmpty ? 'O' : ownerName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.gradient,
                            border: Border.all(color: palette.background, width: 2),
                          ),
                          child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ownerName, style: TextStyle(color: palette.foreground, fontSize: 22, fontWeight: FontWeight.w700)),
                Text(salonName, style: TextStyle(color: palette.muted, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder(AppPalette palette) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withValues(alpha: 0.9), size: 32),
            const SizedBox(height: 6),
            const Text('Add shop cover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _photoButton({required String label, required VoidCallback? onTap}) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    AppPalette palette,
    String label,
    TextEditingController controller, {
    bool obscure = false,
    int lines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : lines,
        keyboardType: keyboard,
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

  Future<void> _openAuth({required bool signup}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(state: widget.state, role: UserRole.owner, startOnSignup: signup),
      ),
    );
    if (mounted) {
      setState(_fill);
    }
  }

  Future<void> _pickPhoto({required bool cover}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: cover ? 45 : 70);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final encoded = base64Encode(await File(picked.path).readAsBytes());
      await widget.state.saveSalon({
        if (cover) 'image_base64': encoded,
        if (!cover) 'owner_image_base64': encoded,
      });
      if (mounted) {
        setState(() => _message = cover ? 'Shop cover updated.' : 'Profile photo updated.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await widget.state.saveSalon({
        'owner_name': _name.text.trim(),
        'name': _salon.text.trim(),
        'description': _description.text.trim(),
        'location': _address.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'opens_at': _opens.text.trim(),
        'open_until': _closes.text.trim(),
      });
      if (mounted) {
        setState(() {
          _editing = false;
          _message = 'Profile saved.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _savePassword() async {
    if (_newPassword.text.length < 6) {
      setState(() => _passwordMessage = 'New password must be at least 6 characters.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _passwordMessage = 'New passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _passwordMessage = null;
    });
    try {
      await widget.state.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) {
        setState(() => _passwordMessage = 'Password updated.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _passwordMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final palette = AppPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete account?', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
        content: Text('This removes your account and signs you out.', style: TextStyle(color: palette.muted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel', style: TextStyle(color: palette.muted))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await widget.state.deleteAccount();
    }
  }
}
