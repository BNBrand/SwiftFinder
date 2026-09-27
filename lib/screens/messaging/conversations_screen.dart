import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_view.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ActivityProvider>().loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<ActivityProvider>(
      builder: (context, p, _) {
        if (p.conversations.isEmpty)
          return const EmptyView(
            icon: Icons.chat_bubble_outline,
            title: 'No conversations',
            message:
                'Start a conversation from an item when you need to contact its poster.',
          );
        return RefreshIndicator(
          onRefresh: p.loadConversations,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: p.conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = p.conversations[i];
              final me = context.read<AuthProvider>().user?.id ?? 0;
              final other = c.otherUser(me);
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (other?.name.isNotEmpty ?? false)
                          ? other!.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(other?.name ?? 'SwiftFinder user'),
                  subtitle: Text(
                    c.item?.title ?? 'Conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(conversation: c),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Messages')),
            body: body,
          );
  }
}
