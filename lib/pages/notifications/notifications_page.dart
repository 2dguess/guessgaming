import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/in_app_notification.dart';
import '../../state/notifications/notifications_controller.dart';
import '../../utils/time_ago.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAllNotificationsRead(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsCountProvider);
          await ref.read(notificationsProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.paddingXL),
                child: Text('Could not load notifications: $e'),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];
                return _tile(context, n);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, InAppNotificationItem n) {
    final (icon, color) = switch (n.iconKind) {
      IconKind.like => (Icons.favorite, AppTheme.likeColor),
      IconKind.follow => (Icons.person_add, AppTheme.successColor),
      IconKind.comment => (Icons.comment, AppTheme.primaryColor),
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: n.actorUsername,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' ${n.actionLabel}'),
          ],
        ),
      ),
      subtitle: Text(
        formatTimeAgo(n.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        if (n.postId != null) {
          context.push('/post/${n.postId}');
        }
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsCountProvider);
      },
    );
  }
}
