import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/notifications/notifications_controller.dart';

/// App bar bell with unread count; opens `/notifications`.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final n = unread.maybeWhen(data: (c) => c, orElse: () => 0);

    return Badge(
      isLabelVisible: n > 0,
      label: Text(
        n > 99 ? '99+' : '$n',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: () => context.push('/notifications'),
      ),
    );
  }
}
