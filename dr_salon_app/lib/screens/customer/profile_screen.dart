import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/gmail.dart';
import '../../widgets/style.dart';
import '../auth_screen.dart';
import 'salon_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  late final _name = TextEditingController();
  late final _location = TextEditingController();
  late final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  String? _accountMessage;
  String? _draftAvatar;

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  void _fill() {
    _name.text = widget.state.customerName;
    _location.text = widget.state.profileLocation;
    _email.text = widget.state.customerEmail;
    _draftAvatar = widget.state.avatarPath;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = widget.state;
    final signedIn = state.isSignedIn;
    final displayName = signedIn && state.customerName.isNotEmpty ? state.customerName : 'Guest';
    final saved = state.salons.where((salon) => state.savedSalonIds.contains(salon.id)).toList();
    final bookings = state.visibleAppointments.length;
    final avatar = _draftAvatar ?? state.avatarPath;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _identity(palette, displayName, avatar, signedIn),
          const SizedBox(height: 20),
          if (_editing)
            _editCard(palette)
          else if (signedIn)
            _detailsCard(palette, state)
          else ...[
            GradientButton(label: 'Sign In', onPressed: () => _openAuth(signup: false)),
            const SizedBox(height: 12),
            _outlineButton(
              label: 'Create account',
              onPressed: () => _openAuth(signup: true),
              color: AppColors.purple,
              border: AppColors.purple.withValues(alpha: 0.55),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat(palette, Icons.calendar_month_outlined, AppColors.purple, '$bookings', 'Total Bookings', () => state.openCustomerTab(1))),
              const SizedBox(width: 12),
              Expanded(child: _stat(palette, Icons.favorite_border, const Color(0xFFF472B6), '${saved.length}', 'Saved Salons', null)),
            ],
          ),
          const SizedBox(height: 24),
          _section(palette, 'Account'),
          const SizedBox(height: 10),
          _menu(palette, Icons.person_outline, AppColors.purple, 'Edit Profile', _startEdit),
          _menu(palette, Icons.calendar_month_outlined, AppColors.violet, 'Booking History', () => state.openCustomerTab(1)),
          _menu(palette, Icons.credit_card_outlined, AppColors.gold, 'Payment Methods', _payments),
          _menu(palette, Icons.settings_outlined, AppColors.muted, 'Settings', _settings),
          const SizedBox(height: 8),
          _section(palette, 'Saved Salons', trailing: '${saved.length} saved'),
          const SizedBox(height: 10),
          if (saved.isEmpty)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.favorite_border, color: palette.muted, size: 32),
                  const SizedBox(height: 10),
                  Text('No saved salons yet', style: TextStyle(color: palette.muted, fontSize: 14)),
                ],
              ),
            )
          else
            ...saved.map(
              (salon) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalonDetailsScreen(state: state, salon: salon)));
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          salon.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 64,
                            height: 64,
                            color: palette.input,
                            child: Icon(Icons.storefront_outlined, color: palette.muted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(salon.name, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(salon.location, style: TextStyle(color: palette.muted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('From PKR ${salon.startingPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: palette.muted),
                    ],
                  ),
                ),
              ),
            ),
          if (signedIn && !_editing) ...[
            const SizedBox(height: 12),
            if (_accountMessage != null) ...[
              Text(
                _accountMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _accountMessage == 'Account updated.' ? AppColors.green : AppColors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            _outlineButton(
              label: 'Log out',
              icon: Icons.logout,
              onPressed: () => state.signOut(),
              color: palette.foreground,
              border: palette.border,
            ),
            const SizedBox(height: 10),
            _outlineButton(
              label: 'Delete account',
              icon: Icons.delete_outline,
              onPressed: _deleteAccount,
              color: AppColors.red,
              border: const Color(0x88EF4444),
              fill: AppColors.red.withValues(alpha: 0.08),
            ),
          ],
        ],
      ),
    );
  }

  Widget _identity(AppPalette palette, String displayName, String? avatar, bool signedIn) {
    return Column(
      children: [
        _avatar(displayName, avatar, palette, signedIn),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.foreground, fontSize: 26, fontWeight: FontWeight.w700, height: 1.1),
        ),
        const SizedBox(height: 8),
        if (signedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: const Text('Premium Member', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
          )
        else
          Text(
            'Browse salons, then sign in to book',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 14, height: 1.35),
          ),
      ],
    );
  }

  Widget _detailsCard(AppPalette palette, AppState state) {
    return GlassCard(
      child: Column(
        children: [
          _infoRow(palette, Icons.mail_outline, AppColors.violet, state.customerEmail.isEmpty ? 'No email on file' : state.customerEmail),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: palette.border),
          ),
          _infoRow(palette, Icons.location_on_outlined, AppColors.gold, state.profileLocation),
        ],
      ),
    );
  }

  Widget _infoRow(AppPalette palette, IconData icon, Color color, String label) {
    return Row(
      children: [
        _iconBox(icon, color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: palette.foreground, fontSize: 15))),
      ],
    );
  }

  Widget _editCard(AppPalette palette) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit profile', style: TextStyle(color: palette.foreground, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Leave the password fields blank to keep your current password.', style: TextStyle(color: palette.muted, fontSize: 12, height: 1.35)),
          const SizedBox(height: 16),
          _labeledField(palette, 'Full name', _name),
          _labeledField(palette, 'Email', _email, keyboard: TextInputType.emailAddress),
          _labeledField(palette, 'Location', _location),
          _labeledField(palette, 'Current password', _currentPassword, obscure: true),
          _labeledField(palette, 'New password', _newPassword, obscure: true),
          if (_accountMessage != null) ...[
            Text(
              _accountMessage!,
              style: TextStyle(color: _accountMessage == 'Account updated.' ? AppColors.green : AppColors.red, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          GradientButton(label: _saving ? 'Saving...' : 'Save changes', onPressed: _saving ? null : _save),
          const SizedBox(height: 10),
          _outlineButton(
            label: 'Cancel',
            onPressed: _saving
                ? null
                : () => setState(() {
                      _editing = false;
                      _accountMessage = null;
                      _fill();
                    }),
            color: palette.foreground,
            border: palette.border,
          ),
        ],
      ),
    );
  }

  Widget _section(AppPalette palette, String title, {String? trailing}) {
    return Row(
      children: [
        Text(title, style: TextStyle(color: palette.foreground, fontSize: 17, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (trailing != null) Text(trailing, style: TextStyle(color: palette.muted, fontSize: 13)),
      ],
    );
  }

  Widget _outlineButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required Color border,
    IconData? icon,
    Color? fill,
  }) {
    final style = OutlinedButton.styleFrom(
      backgroundColor: fill,
      foregroundColor: color,
      minimumSize: const Size.fromHeight(52),
      side: BorderSide(color: border, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
    if (icon == null) {
      return OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
    );
  }

  Widget _avatar(String name, String? path, AppPalette palette, bool signedIn) {
    final file = path == null ? null : File(path);
    final hasPhoto = file != null && file.existsSync();
    return GestureDetector(
      onTap: signedIn ? _pickAvatar : null,
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient),
              child: CircleAvatar(
                backgroundColor: palette.background,
                backgroundImage: hasPhoto ? FileImage(file) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        name.isEmpty ? 'G' : name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            if (signedIn)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradient,
                    border: Border.all(color: palette.background, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _labeledField(AppPalette palette, String label, TextEditingController controller, {bool obscure = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: TextStyle(color: palette.foreground, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.input,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.purple, width: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppPalette palette, IconData icon, Color color, String value, String label, VoidCallback? onTap) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: palette.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _menu(AppPalette palette, IconData icon, Color color, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _startEdit() async {
    if (!widget.state.isSignedIn) {
      await _openAuth(signup: false);
      return;
    }
    setState(() {
      _fill();
      _editing = true;
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _draftAvatar = picked.path);
    if (widget.state.isSignedIn) {
      await widget.state.updateCustomerDetails(
        name: widget.state.customerName.isEmpty ? 'Customer' : widget.state.customerName,
        phone: widget.state.customerPhone,
        location: widget.state.profileLocation,
        avatar: picked.path,
      );
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _accountMessage = null;
    });
    try {
      final name = _name.text.trim();
      if (name.isEmpty) {
        setState(() => _accountMessage = 'Enter your name.');
        return;
      }
      await widget.state.updateCustomerDetails(
        name: name,
        phone: widget.state.customerPhone,
        location: _location.text.trim(),
        avatar: _draftAvatar,
      );
      final email = _email.text.trim();
      if (email.isNotEmpty && email != widget.state.customerEmail) {
        if (!isGmailAddress(email)) {
          setState(() => _accountMessage = gmailFormatError);
          return;
        }
        await widget.state.updateProfile(name: name, phone: widget.state.customerPhone, email: email);
      }
      if (_newPassword.text.trim().isNotEmpty) {
        await widget.state.changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text.trim(),
        );
        _currentPassword.clear();
        _newPassword.clear();
      }
      if (mounted) {
        setState(() {
          _editing = false;
          _accountMessage = 'Account updated.';
          _fill();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _accountMessage = error.toString());
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
        content: Text(
          'This removes your account and signs you out. This cannot be undone.',
          style: TextStyle(color: palette.muted, height: 1.4),
        ),
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

  Future<void> _openAuth({required bool signup}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          state: widget.state,
          role: UserRole.customer,
          startOnSignup: signup,
        ),
      ),
    );
    if (mounted) {
      setState(_fill);
    }
  }

  void _payments() {
    final palette = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Methods', style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pay at the salon', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                          Text('Card payments are not taken in the app.', style: TextStyle(color: palette.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final palette = AppPalette.of(context);
        var deleteConfirm = false;
        return StatefulBuilder(
          builder: (context, setSheet) {
            final state = widget.state;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Settings', style: TextStyle(color: palette.foreground, fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  _switchRow(
                    palette,
                    icon: state.darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: AppColors.gold,
                    title: 'Appearance',
                    subtitle: state.darkMode ? 'Dark Mode' : 'Light Mode',
                    value: state.darkMode,
                    onChanged: (_) {
                      state.toggleTheme();
                      setSheet(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _switchRow(
                    palette,
                    icon: state.notificationsEnabled ? Icons.notifications_outlined : Icons.notifications_off_outlined,
                    color: AppColors.purple,
                    title: 'Notifications',
                    subtitle: state.notificationsEnabled ? 'Enabled' : 'Disabled',
                    value: state.notificationsEnabled,
                    onChanged: (value) {
                      state.setNotifications(value);
                      setSheet(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    onTap: () {
                      if (!deleteConfirm) {
                        setSheet(() => deleteConfirm = true);
                        return;
                      }
                      state.clearBookingHistory();
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Delete Booking History', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
                              Text(
                                deleteConfirm ? 'Tap again to confirm' : '${state.visibleAppointments.length} bookings stored',
                                style: TextStyle(color: palette.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(deleteConfirm ? 'Confirm?' : '', style: const TextStyle(color: AppColors.red, fontSize: 12)),
                      ],
                    ),
                  ),
                    if (state.isSignedIn) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteAccount();
                        },
                        child: const Text('Delete account', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _switchRow(
    AppPalette palette, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.purple),
        ],
      ),
    );
  }
}
