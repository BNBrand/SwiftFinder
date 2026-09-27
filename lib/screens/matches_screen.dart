import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/common/empty_view.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/common/item_card.dart';
import 'item_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.item});

  final FinderItem item;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<FinderItem>? matches;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final v = await context.read<ItemProvider>().loadMatches(widget.item.id);
      if (mounted) setState(() => matches = v);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Potential matches')),
      body: loading
          ? const LoadingView(message: 'Looking for similar reports...')
          : error != null
          ? ErrorView(message: error!, onRetry: _load)
          : matches!.isEmpty
          ? const EmptyView(
              icon: Icons.link_off_outlined,
              title: 'No matches yet',
              message:
                  'SwiftFinder will show related reports here when category, location and date line up.',
            )
          : LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1000
                    ? 3
                    : c.maxWidth >= 650
                    ? 2
                    : 1;
                return GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: matches!.length,
                  itemBuilder: (_, i) {
                    final item = matches![i];
                    return ItemCard(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: item),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
