import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/chat/dm_controller.dart';

/// Feed app bar: chats icon with badge = number of conversations with unread inbound messages.
class ChatInboxButton extends ConsumerWidget {
  const ChatInboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(dmUnreadConversationsCountProvider);
    final n = unread.maybeWhen(data: (c) => c, orElse: () => 0);

    return Badge(
      isLabelVisible: n > 0,
      label: Text(
        n > 99 ? '99+' : '$n',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_bubble_outline),
        tooltip: 'Chats',
        onPressed: () => context.push('/chats'),
      ),
    );
  }
}
