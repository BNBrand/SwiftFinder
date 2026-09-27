import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/claim.dart';
import '../../models/item.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../item_detail_screen.dart';
import '../messaging/conversations_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ActivityProvider>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your activity.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My activity')),
      body:
          activity.loading &&
              activity.myItems.isEmpty &&
              activity.myClaims.isEmpty
          ? const LoadingView(message: 'Loading your activity…')
          : activity.error != null &&
                activity.myItems.isEmpty &&
                activity.myClaims.isEmpty
          ? ErrorView(message: activity.error!, onRetry: activity.loadAll)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Reports'),
                        icon: Icon(Icons.inventory_2_outlined),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Claims'),
                        icon: Icon(Icons.fact_check_outlined),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text('Favorites'),
                        icon: Icon(Icons.favorite_border),
                      ),
                      ButtonSegment(
                        value: 3,
                        label: Text('Messages'),
                        icon: Icon(Icons.chat_bubble_outline),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                ),
                Expanded(
                  child: _tab == 0
                      ? _Reports(items: activity.myItems)
                      : _tab == 1
                      ? _Claims(claims: activity.myClaims)
                      : _tab == 2
                      ? const _Favorites()
                      : const ConversationsScreen(embedded: true),
                ),
              ],
            ),
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports({required this.items});

  final List<FinderItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty)
      return const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'No reports yet',
        message: 'Your lost and found reports will appear here.',
      );
    return RefreshIndicator(
      onRefresh: context.read<ActivityProvider>().loadMyItems,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  item.type == 'lost' ? Icons.search : Icons.volunteer_activism,
                ),
              ),
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${_pretty(item.status)} • ${item.location}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Claims extends StatelessWidget {
  const _Claims({required this.claims});

  final List<FinderClaim> claims;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty)
      return const EmptyView(
        icon: Icons.fact_check_outlined,
        title: 'No claims yet',
        message: 'Claims you submit on found or lost reports will appear here.',
      );
    return RefreshIndicator(
      onRefresh: context.read<ActivityProvider>().loadMyClaims,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: claims.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = claims[i];
          final item = c.item;
          return Card(
            elevation: 0,
            child: ListTile(
              leading: _StatusIcon(status: c.status),
              title: Text(item?.title ?? 'Report #${c.itemId}'),
              subtitle: Text(
                '${_pretty(c.status)} • ${c.message}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: item == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final icon = status == 'accepted'
        ? Icons.check_circle_outline
        : status == 'rejected'
        ? Icons.cancel_outlined
        : Icons.hourglass_empty;
    return Icon(icon);
  }
}

String _pretty(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
    .join(' ');

class _Favorites extends StatefulWidget {
  const _Favorites();

  @override
  State<_Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<_Favorites> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ItemProvider>().loadFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ItemProvider>();
    if (p.favoritesLoading && p.favorites.isEmpty)
      return const LoadingView(message: 'Loading favorites…');
    if (p.favoritesError != null && p.favorites.isEmpty)
      return ErrorView(message: p.favoritesError!, onRetry: p.loadFavorites);
    if (p.favorites.isEmpty)
      return const EmptyView(
        icon: Icons.favorite_border,
        title: 'No favorites yet',
        message:
            'Save reports you want to follow so you can find them quickly.',
      );
    return RefreshIndicator(
      onRefresh: p.loadFavorites,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: p.favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = p.favorites[i];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(item.title),
              subtitle: Text('${_pretty(item.status)} • ${item.location}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              ),
            ),
          );
        },
      ),
    );
  }
}
