import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.state,
    required this.salonId,
    required this.customerId,
    required this.title,
  });

  final AppState state;
  final String salonId;
  final String customerId;
  final String title;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _text = TextEditingController();
  StreamSubscription<List<ChatLine>>? _subscription;
  List<ChatLine> _lines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _listen() {
    _subscription?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = widget.state.watchMessages(widget.salonId, customerId: widget.customerId).listen(
      (lines) {
        if (!mounted) {
          return;
        }
        setState(() {
          _lines = lines;
          _loading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      },
    );
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) {
      return;
    }
    _text.clear();
    try {
      await widget.state.sendMessage(widget.salonId, body, customerId: widget.customerId);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat'),
        content: Text('Delete the chat with ${widget.title}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      await widget.state.deleteChat(widget.salonId, customerId: widget.customerId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Delete chat',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.red)),
                      for (final message in _lines)
                        Align(
                          alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: GlassCard(
                                child: Text(message.body, style: TextStyle(color: palette.foreground)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    style: TextStyle(color: palette.foreground),
                    decoration: InputDecoration(
                      hintText: 'Message the salon',
                      hintStyle: TextStyle(color: palette.muted),
                      filled: true,
                      fillColor: palette.input,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send, color: AppColors.purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
