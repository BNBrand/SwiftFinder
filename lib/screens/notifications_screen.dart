import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/common/empty_view.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (p.unreadCount > 0)
            TextButton(
              onPressed: p.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: p.loading && p.notifications.isEmpty
          ? const LoadingView()
          : p.error != null && p.notifications.isEmpty
          ? ErrorView(message: p.error!, onRetry: p.load)
          : p.notifications.isEmpty
          ? const EmptyView(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message:
                  'Updates about your reports, claims and messages will appear here.',
            )
          : RefreshIndicator(
              onRefresh: p.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: p.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = p.notifications[i];
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      onTap: () => n.isRead ? null : p.markRead(n.id),
                      leading: CircleAvatar(child: Icon(_icon(n.type))),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w500
                              : FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(n.message),
                      trailing: n.isRead
                          ? null
                          : const Icon(Icons.circle, size: 9),
                    ),
                  );
                },
              ),
            ),
    );
  }

  IconData _icon(String type) => type.contains('claim')
      ? Icons.fact_check_outlined
      : type.contains('message')
      ? Icons.chat_bubble_outline
      : type.contains('match')
      ? Icons.link_outlined
      : Icons.notifications_outlined;
}
