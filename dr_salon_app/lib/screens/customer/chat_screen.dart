import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/style.dart';
import 'chat_thread_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  StreamSubscription<List<ChatThread>>? _subscription;
  List<ChatThread> _threads = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isSignedIn != widget.state.isSignedIn || oldWidget.state.token != widget.state.token) {
      _listen();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listen() {
    _subscription?.cancel();
    if (!widget.state.isSignedIn) {
      setState(() {
        _threads = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = widget.state.watchChats().listen(
      (threads) {
        if (!mounted) {
          return;
        }
        setState(() {
          _threads = threads;
          _loading = false;
          _error = null;
        });
        widget.state.chatCount = threads.length;
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

  Future<void> _confirmDelete(ChatThread item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat'),
        content: Text('Delete the chat with ${item.title}? This cannot be undone.'),
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
      await widget.state.deleteChat(item.salonId, customerId: item.customerId);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final signedIn = widget.state.isSignedIn;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _listen(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('Messages', style: TextStyle(color: palette.foreground, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              signedIn
                  ? (widget.state.role == UserRole.owner
                      ? 'Chat with customers about their bookings'
                      : 'Booking updates and chats with the salon')
                  : 'Sign in from Profile to see messages',
              style: TextStyle(color: palette.muted),
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.purple)),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.red)),
            if (signedIn && !_loading && _threads.isEmpty)
              Text(
                widget.state.role == UserRole.owner
                    ? 'Customer chats will show up here after they book.'
                    : 'Your booking messages will show up here.',
                style: TextStyle(color: palette.muted),
              ),
            ..._threads.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatThreadScreen(
                          state: widget.state,
                          salonId: item.salonId,
                          customerId: item.customerId,
                          title: item.title,
                        ),
                      ));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.purple,
                          child: Icon(
                            widget.state.role == UserRole.owner ? Icons.person_outline : Icons.storefront_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: TextStyle(color: palette.foreground, fontWeight: FontWeight.w700)),
                              Text(item.lastMessage, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete chat',
                          onPressed: () => _confirmDelete(item),
                          icon: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
