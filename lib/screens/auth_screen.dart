import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/gmail.dart';
import '../widgets/style.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.state,
    required this.role,
    this.startOnSignup = false,
    this.initialEmail,
    this.initialPassword,
  });

  final AppState state;
  final UserRole role;
  final bool startOnSignup;
  final String? initialEmail;
  final String? initialPassword;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signup = widget.startOnSignup;
  bool _reset = false;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;
  String? _notice;
  String? _avatarPath;
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  late final _password = TextEditingController(text: widget.initialPassword ?? '');
  final _name = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _avatarPath = picked.path);
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    if (_reset) {
      if (!isGmailAddress(email)) {
        setState(() => _error = gmailFormatError);
        return;
      }
      setState(() {
        _busy = true;
        _error = null;
        _notice = null;
      });
      try {
        final message = await widget.state.forgotPassword(email);
        if (mounted) {
          setState(() => _notice = message);
        }
      } catch (error) {
        setState(() => _error = error.toString());
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
      return;
    }
    if (_signup && !isGmailAddress(email)) {
      setState(() => _error = gmailFormatError);
      return;
    }
    if (!_signup && (!email.contains('@') || !email.contains('.'))) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_signup) {
      if (name.isEmpty) {
        setState(() => _error = 'Enter your name.');
        return;
      }
      if (_confirm.text != password) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_signup) {
        await widget.state.signUp(email: email, password: password, name: name, phone: '');
        if (_avatarPath != null) {
          await widget.state.updateCustomerDetails(
            name: widget.state.customerName.isEmpty ? name : widget.state.customerName,
            phone: widget.state.customerPhone,
            location: widget.state.profileLocation,
            avatar: _avatarPath,
          );
        }
      } else {
        await widget.state.signIn(email, password);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _useDemo() {
    final owner = widget.role == UserRole.owner;
    setState(() {
      _signup = false;
      _reset = false;
      _email.text = owner ? 'owner@demo.com' : 'customer@demo.com';
      _password.text = 'Demo1234!';
      _confirm.text = 'Demo1234!';
      _error = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final owner = widget.role == UserRole.owner;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, color: palette.foreground),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/App logo.jpg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _reset ? 'Reset password' : (_signup ? 'Create account' : 'Sign in'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _reset
                          ? 'We will email a reset link to your Gmail address.'
                          : (owner
                              ? 'Manage your salon, bookings, and services.'
                              : 'Book salons and keep your style recommendations.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    if (!_reset) ...[
                      _modeSwitch(palette),
                      const SizedBox(height: 22),
                    ],
                    if (_signup && !_reset) ...[
                      _photoPicker(palette),
                      const SizedBox(height: 18),
                      _field(palette, _name, 'Full name', icon: Icons.person_outline, textInputAction: TextInputAction.next),
                    ],
                    _field(
                      palette,
                      _email,
                      'Email',
                      icon: Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                      textInputAction: _reset ? TextInputAction.done : TextInputAction.next,
                      helper: _signup || _reset ? gmailFormatHint : null,
                    ),
                    if (!_reset)
                    _field(
                      palette,
                      _password,
                      'Password',
                      icon: Icons.lock_outline,
                      obscure: _hidePassword,
                      onToggle: () => setState(() => _hidePassword = !_hidePassword),
                      textInputAction: _signup ? TextInputAction.next : TextInputAction.done,
                    ),
                    if (_signup && !_reset)
                      _field(
                        palette,
                        _confirm,
                        'Confirm password',
                        icon: Icons.lock_outline,
                        obscure: _hideConfirm,
                        onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                        textInputAction: TextInputAction.done,
                      ),
                    if (!_signup && !_reset)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _reset = true;
                                    _error = null;
                                    _notice = null;
                                  }),
                          child: const Text('Forgot password?', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (_notice != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
                        ),
                        child: Text(_notice!, style: const TextStyle(color: AppColors.green, fontSize: 13, height: 1.3)),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13, height: 1.3)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: _busy ? 'Please wait...' : (_reset ? 'Send reset link' : (_signup ? 'Create account' : 'Sign in')),
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: 8),
                    if (_reset)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _reset = false;
                                  _error = null;
                                  _notice = null;
                                }),
                        child: Text('Back to sign in', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600)),
                      )
                    else
                      TextButton(
                        onPressed: _busy ? null : _useDemo,
                        child: Text('Use demo account', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSwitch(AppPalette palette) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.input,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          _segment('Sign in', !_signup, palette, () => setState(() {
                _signup = false;
                _reset = false;
                _error = null;
                _notice = null;
              })),
          _segment('Create account', _signup, palette, () => setState(() {
                _signup = true;
                _reset = false;
                _error = null;
                _notice = null;
              })),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, AppPalette palette, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: _busy ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradient : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : palette.muted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPicker(AppPalette palette) {
    final file = _avatarPath == null ? null : File(_avatarPath!);
    final hasPhoto = file != null && file.existsSync();
    return Column(
      children: [
        GestureDetector(
          onTap: _busy ? null : _pickPhoto,
          child: Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto ? AppColors.gradient : null,
              border: hasPhoto ? null : Border.all(color: palette.border, width: 1.5),
              color: hasPhoto ? null : palette.input,
            ),
            child: CircleAvatar(
              backgroundColor: palette.background,
              backgroundImage: hasPhoto ? FileImage(file) : null,
              child: hasPhoto
                  ? null
                  : Icon(Icons.add_a_photo_outlined, color: palette.muted, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Profile photo', style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w600)),
        Text('Optional', style: TextStyle(color: palette.muted, fontSize: 12)),
      ],
    );
  }

  Widget _field(
    AppPalette palette,
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboard,
    TextInputAction? textInputAction,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            textInputAction: textInputAction,
            style: TextStyle(color: palette.foreground, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: palette.muted, size: 20),
              suffixIcon: onToggle == null
                  ? null
                  : IconButton(
                      onPressed: onToggle,
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: palette.muted, size: 20),
                    ),
              filled: true,
              fillColor: palette.input,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.purple, width: 1.4)),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper, style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
