import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../services/api_service.dart';
import '../widgets/common/app_text_field.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key, this.item});

  final FinderItem? item;

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  final details = TextEditingController();
  final picker = ImagePicker();
  final List<MultipartUpload> images = [];
  String type = 'lost', contact = 'in_app';
  int? categoryId;
  DateTime date = DateTime.now();
  TimeOfDay? time;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      type = i.type;
      title.text = i.title;
      description.text = i.description;
      location.text = i.location;
      details.text = i.identifyingDetails ?? '';
      date = DateTime.tryParse(i.occurredOn) ?? DateTime.now();
      if (i.occurredAt != null) {
        final parts = i.occurredAt!.split(':');
        if (parts.length == 2) {
          time = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      contact = i.contactPreference ?? 'in_app';
      categoryId = i.category?.id;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ItemProvider>().loadCategories(),
    );
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'lost' ? 'Report lost item' : 'Report found item'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.item == null
                      ? 'Create a detailed report'
                      : 'Edit report',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item == null
                      ? 'Clear photos and identifying details make recovery much easier.'
                      : 'Update the report details below. Existing photos will be kept.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'lost',
                      label: Text('Lost'),
                      icon: Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: 'found',
                      label: Text('Found'),
                      icon: Icon(Icons.volunteer_activism),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: title,
                  label: 'Item title',
                  hint: 'e.g. Black Samsung phone',
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'A title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                if (state.categoriesLoading)
                  const LinearProgressIndicator()
                else if (state.categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: state.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: description,
                  label: 'Description',
                  hint: 'Describe the item.',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 5,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Describe the item'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: details,
                  label: 'Identifying details',
                  hint: 'Colour, marks, case, serial number, etc.',
                  prefixIcon: Icons.fingerprint,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: location,
                  label: type == 'lost' ? 'Location lost' : 'Location found',
                  hint: 'Where did this happen?',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Add a location' : null,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: Text(
                          type == 'lost' ? 'Date lost' : 'Date found',
                        ),
                        subtitle: Text(_date(date)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickDate,
                      ),
                      ListTile(
                        leading: const Icon(Icons.schedule_outlined),
                        title: const Text('Approximate time'),
                        subtitle: Text(
                          time == null
                              ? 'Not specified'
                              : time!.format(context),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: contact,
                  decoration: const InputDecoration(
                    labelText: 'Contact preference',
                    prefixIcon: Icon(Icons.contact_mail_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'in_app',
                      child: Text('In-app messaging'),
                    ),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('WhatsApp'),
                    ),
                  ],
                  onChanged: (v) => setState(() => contact = v ?? contact),
                ),
                const SizedBox(height: 18),
                _PhotoPicker(
                  images: images,
                  onAdd: _pickImages,
                  onRemove: (i) => setState(() => images.removeAt(i)),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(
                    submitting
                        ? (widget.item == null ? 'Publishing…' : 'Saving…')
                        : (widget.item == null
                              ? 'Publish report'
                              : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked.isEmpty) return;
    for (final x in picked.take(6 - images.length)) {
      final b = await x.readAsBytes();
      images.add(
        MultipartUpload(
          field: 'images[]',
          bytes: b,
          filename: x.name,
          mediaType: _media(x.name),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  http.MediaType? _media(String n) => n.toLowerCase().endsWith('.png')
      ? http.MediaType('image', 'png')
      : http.MediaType('image', 'jpeg');

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: date,
    );
    if (d != null && mounted) setState(() => date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );
    if (t != null && mounted) setState(() => time = t);
  }

  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    if (!context.read<AuthProvider>().isSignedIn) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to publish your report.')),
        );
      return;
    }
    setState(() => submitting = true);
    try {
      if (widget.item == null) {
        await context.read<ItemProvider>().createItem(
          type: type,
          title: title.text.trim(),
          description: description.text.trim(),
          location: location.text.trim(),
          occurredOn:
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          occurredAt: time == null
              ? null
              : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
          categoryId: categoryId,
          identifyingDetails: details.text,
          contactPreference: contact,
          images: images,
        );
      } else {
        await context.read<ItemProvider>().updateItem(
          itemId: widget.item!.id,
          type: type,
          title: title.text.trim(),
          description: description.text.trim(),
          location: location.text.trim(),
          occurredOn:
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          occurredAt: time == null
              ? null
              : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
          categoryId: categoryId,
          identifyingDetails: details.text,
          contactPreference: contact,
          images: images,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.userMessage : e.toString()),
          ),
        );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<MultipartUpload> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Photos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: images.length >= 6 ? null : onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add photos'),
          ),
        ],
      ),
      if (images.isEmpty)
        Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: const Center(child: Text('Add up to 6 photos of the item.')),
        )
      else
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Stack(
              children: [
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      images[i].bytes,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 38),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filledTonal(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
