import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

import '../models/item.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/app_network_image.dart';
import 'claim_review_screen.dart';
import 'matches_screen.dart';
import 'messaging/chat_screen.dart';
import 'auth_screen.dart';
import 'report_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final FinderItem item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late FinderItem _item;
  bool _loading = true;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await context.read<ItemProvider>().getItem(_item.id);
      if (mounted) setState(() => _item = fresh);
    } catch (_) {
      // The list item remains usable when the detail request fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _requireAuth() async {
    final auth = context.read<AuthProvider>();
    if (auth.isSignedIn) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return context.read<AuthProvider>().isSignedIn;
  }

  Future<void> _toggleFavorite() async {
    if (!await _requireAuth() || !mounted) return;
    setState(() => _favoriteLoading = true);
    try {
      final value = await context.read<ItemProvider>().toggleFavorite(_item);
      setState(() => _item = _item.copyWith(isFavorited: value));
      _snack(value ? 'Saved to your favorites.' : 'Removed from favorites.');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _submitClaim() async {
    if (!await _requireAuth() || !mounted) return;
    final result = await showDialog<_ClaimData>(
      context: context,
      builder: (_) => const _ClaimDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await context.read<ItemProvider>().submitClaim(
        itemId: _item.id,
        message: result.message,
        supportingInformation: result.supportingInformation,
        supportingFile: result.file,
      );
      if (mounted) _snack('Your claim has been submitted.');
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    }
  }

  Future<void> _contactPoster() async {
    if (!await _requireAuth() || !mounted) return;
    try {
      final conversation = await context.read<ItemProvider>().startConversation(
        _item.id,
      );
      if (mounted)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    }
  }

  Future<void> _ownerAction(String action) async {
    try {
      if (action == 'edit') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportItemScreen(item: _item)),
        );
        if (mounted) setState(() => _loading = true);
        final updated = await context.read<ItemProvider>().getItem(_item.id);
        if (mounted)
          setState(() {
            _item = updated;
            _loading = false;
          });
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete report?'),
            content: const Text('This permanently removes the report.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await context.read<ItemProvider>().deleteItem(_item.id);
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        final status = action == 'found'
            ? (_item.type == 'lost' ? 'found' : 'returned')
            : 'closed';
        await context.read<ItemProvider>().changeStatus(_item.id, status);
        final updated = await context.read<ItemProvider>().getItem(_item.id);
        if (mounted) {
          setState(() => _item = updated);
          _snack('Report status updated.');
        }
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    }
  }

  Future<void> _reportItem() async {
    final result = await _showSafetyDialog(context, 'Report item');
    if (result == null || !mounted) return;
    try {
      await context.read<ProfileProvider>().reportItem(
        _item.id,
        result.reason,
        result.details,
      );
      _snack('Report submitted.');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _blockPoster() async {
    final id = _item.poster?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block poster?'),
        content: const Text(
          'You will no longer be able to interact with this user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ProfileProvider>().blockUser(id);
      _snack('Poster blocked.');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _item.type == 'lost';
    final canClaim = _item.status == 'active' || _item.status == 'available';
    final isOwner = context.read<AuthProvider>().user?.id == _item.poster?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLost ? 'Lost item' : 'Found item'),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: _ownerAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit report')),
                PopupMenuItem(value: 'found', child: Text('Mark as found')),
                PopupMenuItem(value: 'closed', child: Text('Close report')),
                PopupMenuItem(value: 'delete', child: Text('Delete report')),
              ],
            ),
          if (context.read<AuthProvider>().isSignedIn &&
              context.read<AuthProvider>().user?.id != _item.poster?.id)
            PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'report' ? _reportItem() : _blockPoster(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report item')),
                PopupMenuItem(value: 'block', child: Text('Block poster')),
              ],
            ),
          IconButton(
            tooltip: _item.isFavorited ? 'Remove favorite' : 'Save favorite',
            onPressed: _favoriteLoading ? null : _toggleFavorite,
            icon: _favoriteLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _item.isFavorited ? Icons.favorite : Icons.favorite_border,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final content = _DetailContent(
              item: _item,
              loading: _loading,
              isLost: isLost,
            );
            final actions = _ActionPanel(
              item: _item,
              canClaim: canClaim,
              onClaim: _submitClaim,
              onContact: _contactPoster,
              contactPreference: _item.contactPreference,
              isOwner: isOwner,
              onReviewClaims: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClaimReviewScreen(
                    itemId: _item.id,
                    itemTitle: _item.title,
                  ),
                ),
              ),
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(wide ? 32 : 18),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: content),
                              const SizedBox(width: 24),
                              SizedBox(width: 320, child: actions),
                            ],
                          )
                        : Column(
                            children: [
                              content,
                              const SizedBox(height: 20),
                              actions,
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

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.item,
    required this.loading,
    required this.isLost,
  });

  final FinderItem item;
  final bool loading;
  final bool isLost;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.images.isNotEmpty)
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: item.images.length,
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AppNetworkImage(url: item.images[index].url),
              ),
            ),
          )
        else
          _ImagePlaceholder(isLost: isLost),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(isLost ? 'LOST' : 'FOUND')),
            if (item.category != null) Chip(label: Text(item.category!.name)),
            Chip(label: Text(_pretty(item.status))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          item.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          child: Column(
            children: [
              _InfoTile(Icons.location_on_outlined, 'Location', item.location),
              _InfoTile(
                Icons.calendar_today_outlined,
                isLost ? 'Lost on' : 'Found on',
                item.occurredOn,
              ),
              if (item.occurredAt != null)
                _InfoTile(
                  Icons.schedule_outlined,
                  'Approximate time',
                  item.occurredAt!,
                ),
              if (item.contactPreference != null)
                _InfoTile(
                  Icons.forum_outlined,
                  'Contact preference',
                  _pretty(item.contactPreference!),
                ),
            ],
          ),
        ),
        if (item.identifyingDetails != null &&
            item.identifyingDetails!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Identifying details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.identifyingDetails!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
        const SizedBox(height: 20),
        if (item.poster != null)
          Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  item.poster!.name.isEmpty
                      ? '?'
                      : item.poster!.name[0].toUpperCase(),
                ),
              ),
              title: Text(item.poster!.name),
              subtitle: const Text('Report poster'),
            ),
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  static String _pretty(String value) => value.isEmpty
      ? 'Unknown'
      : value
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.isLost});

  final bool isLost;

  @override
  Widget build(BuildContext context) => Container(
    height: 300,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Center(
      child: Icon(
        isLost ? Icons.search_rounded : Icons.volunteer_activism_rounded,
        size: 76,
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(value), subtitle: Text(label));
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.item,
    required this.canClaim,
    required this.onClaim,
    required this.onContact,
    this.contactPreference,
    required this.isOwner,
    required this.onReviewClaims,
  });

  final FinderItem item;
  final bool canClaim;
  final VoidCallback onClaim;
  final VoidCallback onContact;
  final String? contactPreference;
  final bool isOwner;
  final VoidCallback onReviewClaims;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canClaim)
            FilledButton.icon(
              onPressed: onClaim,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Submit a claim'),
            ),
          if (canClaim) const SizedBox(height: 10),
          if (!isOwner && canClaim) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MatchesScreen(item: item)),
              ),
              icon: const Icon(Icons.link_outlined),
              label: const Text('Potential matches'),
            ),
            const SizedBox(height: 10),
          ],
          if (isOwner) ...[
            OutlinedButton.icon(
              onPressed: onReviewClaims,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Review claims'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contact poster'),
          ),
          if (contactPreference != null) ...[
            const SizedBox(height: 12),
            Text(
              'Preferred contact: ${_pretty(contactPreference!)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    ),
  );

  static String _pretty(String value) => value.replaceAll('_', ' ');
}

class _SafetyResult {
  const _SafetyResult(this.reason, this.details);

  final String reason;
  final String details;
}

Future<_SafetyResult?> _showSafetyDialog(
  BuildContext context,
  String title,
) async {
  String reason = 'suspicious';
  final details = TextEditingController();
  return showDialog<_SafetyResult>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: const [
                DropdownMenuItem(value: 'fake', child: Text('Fake report')),
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(
                  value: 'inappropriate',
                  child: Text('Inappropriate'),
                ),
                DropdownMenuItem(
                  value: 'suspicious',
                  child: Text('Suspicious'),
                ),
                DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
              ],
              onChanged: (v) => setState(() => reason = v ?? reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: details,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _SafetyResult(reason, details.text)),
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}

class _ClaimData {
  const _ClaimData(this.message, this.supportingInformation, this.file);

  final String message;
  final String? supportingInformation;
  final MultipartUpload? file;
}

class _ClaimDialog extends StatefulWidget {
  const _ClaimDialog();

  @override
  State<_ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends State<_ClaimDialog> {
  final _message = TextEditingController();
  final _details = TextEditingController();
  MultipartUpload? _file;

  @override
  void dispose() {
    _message.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.single.bytes == null || !mounted) return;
    final file = result.files.single;
    setState(
      () => _file = MultipartUpload(
        field: 'supporting_file',
        bytes: file.bytes!,
        filename: file.name,
        mediaType: _media(file.name),
      ),
    );
  }

  http.MediaType? _media(String n) {
    final l = n.toLowerCase();
    if (l.endsWith('.pdf')) return http.MediaType('application', 'pdf');
    if (l.endsWith('.doc')) return http.MediaType('application', 'msword');
    if (l.endsWith('.docx')) {
      return http.MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }
    if (l.endsWith('.png')) return http.MediaType('image', 'png');
    return http.MediaType('image', 'jpeg');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Submit a claim'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 3000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Why is this your item?',
              hintText:
                  'Describe details that can help the poster verify your claim.',
            ),
          ),
          const SizedBox(height: 10),
          if (_file != null)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(_file!.filename),
              subtitle: const Text('Supporting file attached'),
              trailing: IconButton(
                onPressed: () => setState(() => _file = null),
                icon: const Icon(Icons.close),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: const Text('Add supporting image or document'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _details,
            maxLines: 4,
            maxLength: 3000,
            decoration: const InputDecoration(
              labelText: 'Supporting information (optional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _message.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                _ClaimData(_message.text, _details.text, _file),
              ),
        child: const Text('Submit claim'),
      ),
    ],
  );
}
