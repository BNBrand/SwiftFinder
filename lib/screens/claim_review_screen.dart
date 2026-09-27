import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/claim.dart';
import '../providers/activity_provider.dart';
import '../widgets/common/empty_view.dart';
import '../widgets/common/loading_view.dart';

class ClaimReviewScreen extends StatefulWidget {
  const ClaimReviewScreen({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  final int itemId;
  final String itemTitle;

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  List<FinderClaim> _claims = [];
  bool _loading = true;
  String? _error;
  int? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await context.read<ActivityProvider>().loadClaimsForItem(
        widget.itemId,
      );
      if (mounted) setState(() => _claims = c);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(FinderClaim claim, String status) async {
    setState(() => _busy = claim.id);
    try {
      await context.read<ActivityProvider>().reviewClaim(claim.id, status);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' ? 'Claim accepted.' : 'Claim rejected.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review claims')),
      body: _loading
          ? const LoadingView(message: 'Loading claims…')
          : _error != null
          ? Center(child: Text(_error!))
          : _claims.isEmpty
          ? const EmptyView(
              icon: Icons.fact_check_outlined,
              title: 'No claims yet',
              message:
                  'When someone claims this report, you can review it here.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _claims.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = _claims[i];
                  final pending = c.status == 'pending';
                  return Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  (c.claimant?.name.isNotEmpty ?? false)
                                      ? c.claimant!.name[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.claimant?.name ?? 'Claimant',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      c.status.toUpperCase(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(c.message),
                          if (c.supportingInformation?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Supporting information',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(c.supportingInformation!),
                          ],
                          if (pending) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: _busy == c.id
                                      ? null
                                      : () => _review(c, 'rejected'),
                                  child: const Text('Reject'),
                                ),
                                FilledButton(
                                  onPressed: _busy == c.id
                                      ? null
                                      : () => _review(c, 'accepted'),
                                  child: _busy == c.id
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Accept'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
