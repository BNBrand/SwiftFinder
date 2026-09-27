import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../config/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/common/empty_view.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/item_card.dart';
import '../widgets/common/loading_view.dart';
import 'auth_screen.dart';
import 'item_detail_screen.dart';
import 'notifications_screen.dart';
import 'activity/activity_screen.dart';
import 'profile_screen.dart';
import 'report_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();

  String? _type;
  int? _categoryId;
  bool _showLocationFilter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ItemProvider>();
      provider.load();
      provider.loadCategories();
      if (context.read<AuthProvider>().isSignedIn)
        context.read<NotificationProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await context.read<ItemProvider>().load(
      type: _type,
      query: _searchController.text,
      categoryId: _categoryId,
      location: _locationController.text,
    );
  }

  void _setType(String? type) {
    setState(() => _type = type);
    _search();
  }

  void _setCategory(ItemCategory? category) {
    setState(() => _categoryId = category?.id);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded),
            SizedBox(width: 8),
            Text('SwiftFinder'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: itemProvider.loading ? null : _search,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (auth.isSignedIn)
            Consumer<NotificationProvider>(
              builder: (context, notifications, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    icon: Icon(
                      notifications.unreadCount > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                    ),
                  ),
                  if (notifications.unreadCount > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notifications.unreadCount > 99 ? '99+' : notifications.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.lightSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (auth.isSignedIn)
            IconButton(
              tooltip: 'My activity',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
              ),
              icon: const Icon(Icons.dashboard_outlined),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: auth.isSignedIn ? 'Account' : 'Sign in',
              onPressed: () async {
                if (!auth.isSignedIn) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              icon: Icon(
                auth.isSignedIn
                    ? Icons.account_circle_outlined
                    : Icons.login_rounded,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportItemScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report item'),
      ),
      body: RefreshIndicator(
        onRefresh: _search,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final padding = wide ? 32.0 : 18.0;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 110),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroHeader(signedIn: auth.isSignedIn),
                        const SizedBox(height: 22),
                        _SearchPanel(
                          searchController: _searchController,
                          locationController: _locationController,
                          showLocationFilter: _showLocationFilter,
                          onSearch: _search,
                          onToggleLocation: () => setState(
                            () => _showLocationFilter = !_showLocationFilter,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FilterChips(
                          type: _type,
                          categoryId: _categoryId,
                          categories: itemProvider.categories,
                          categoriesLoading: itemProvider.categoriesLoading,
                          onTypeChanged: _setType,
                          onCategoryChanged: _setCategory,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _type == null
                                    ? 'Recent reports'
                                    : '${_type![0].toUpperCase()}${_type!.substring(1)} reports',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (!itemProvider.loading &&
                                itemProvider.items.isNotEmpty)
                              Text(
                                '${itemProvider.items.length} shown',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (itemProvider.loading)
                          const LoadingView(message: 'Finding reports…')
                        else if (itemProvider.error != null)
                          ErrorView(
                            message: itemProvider.error!,
                            onRetry: _search,
                          )
                        else if (itemProvider.items.isEmpty)
                          const EmptyView(
                            icon: Icons.search_off_rounded,
                            title: 'No reports found',
                            message:
                                'Try a different keyword, category, type, or location.',
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemProvider.items.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: wide ? 520 : 600,
                                  mainAxisExtent: 430,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                            itemBuilder: (_, index) {
                              final item = itemProvider.items[index];
                              return ItemCard(
                                item: item,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: .78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find it. Return it.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.lightSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search lost and found reports, discover potential matches, and help get belongings back to their owners.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.lightSurface.withValues(alpha: .9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            avatar: Icon(
              signedIn ? Icons.verified_user_outlined : Icons.public,
              color: scheme.primary,
              size: 18,
            ),
            label: Text(signedIn ? 'Signed in' : 'Browse publicly'),
            backgroundColor: AppColors.lightSurface,
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchController,
    required this.locationController,
    required this.showLocationFilter,
    required this.onSearch,
    required this.onToggleLocation,
  });

  final TextEditingController searchController;
  final TextEditingController locationController;
  final bool showLocationFilter;
  final VoidCallback onSearch;
  final VoidCallback onToggleLocation;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search phones, documents, keys…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Search by location',
                        onPressed: onToggleLocation,
                        icon: Icon(
                          showLocationFilter
                              ? Icons.location_on
                              : Icons.location_on_outlined,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  height: 52,
                  child: FilledButton(
                    onPressed: onSearch,
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
            if (showLocationFilter) ...[
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_outlined),
                  hintText: 'Filter by location, e.g. Bamenda',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.type,
    required this.categoryId,
    required this.categories,
    required this.categoriesLoading,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  final String? type;
  final int? categoryId;
  final List<ItemCategory> categories;
  final bool categoriesLoading;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<ItemCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by type',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _typeChip(context, 'All', null, Icons.apps_rounded),
            _typeChip(context, 'Lost', 'lost', Icons.search_rounded),
            _typeChip(
              context,
              'Found',
              'found',
              Icons.volunteer_activism_outlined,
            ),
          ],
        ),
        if (categories.isNotEmpty || categoriesLoading) ...[
          const SizedBox(height: 16),
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (categoriesLoading)
            const SizedBox(
              height: 32,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: categoryId == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: categoryId == category.id,
                        onSelected: (_) => onCategoryChanged(category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _typeChip(
    BuildContext context,
    String label,
    String? value,
    IconData icon,
  ) {
    final selected = type == value;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Theme.of(context).colorScheme.onPrimary : null,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTypeChanged(value),
    );
  }
}
