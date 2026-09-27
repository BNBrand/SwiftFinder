import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/loading_view.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/app_text_field.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProfileProvider>().load(),
    );
  }

  Future<void> _changePhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (x == null || !mounted) return;
    try {
      await context.read<ProfileProvider>().uploadPhoto(
        await x.readAsBytes(),
        x.name,
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editProfile() async {
    final p = context.read<ProfileProvider>();
    final current = p.profile?.user;
    final name = TextEditingController(text: current?.name ?? '');
    final phone = TextEditingController(text: current?.phone ?? '');
    final key = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: name,
                label: 'Name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phone,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              try {
                await p.update(name: name.text, phone: phone.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated.')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final current = TextEditingController(),
        password = TextEditingController(),
        confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    final p = context.read<ProfileProvider>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: current,
                  label: 'Current password',
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required.' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: password,
                  label: 'New password',
                  obscureText: true,
                  validator: (v) => v == null || v.length < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: confirm,
                  label: 'Confirm password',
                  obscureText: true,
                  validator: (v) =>
                      v != password.text ? 'Passwords do not match.' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              try {
                await p.changePassword(
                  currentPassword: current.text,
                  password: password.text,
                  confirmation: confirm.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password changed. Please sign in again.',
                        ),
                      ),
                    );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your account and cannot be undone.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: password,
              label: 'Password',
              obscureText: true,
            ),
          ],
        ),
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
    if (confirmed != true || password.text.isEmpty) return;
    try {
      await context.read<ProfileProvider>().deleteAccount(password.text);
      await context.read<AuthProvider>().logout();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) return const AuthScreen();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: p.loading && p.profile == null
          ? const LoadingView(message: 'Loading profile…')
          : p.error != null && p.profile == null
          ? ErrorView(message: p.error!, onRetry: p.load)
          : RefreshIndicator(
              onRefresh: p.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: p.profile?.user.photoUrl != null
                              ? ClipOval(
                                  child: AppNetworkImage(
                                    url: p.profile!.user.photoUrl!,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : Text(
                                  (p.profile?.user.name.isNotEmpty == true
                                          ? p.profile!.user.name[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: IconButton.filled(
                            onPressed: _changePhoto,
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      p.profile?.user.name ?? '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (p.profile?.user.email != null)
                    Center(child: Text(p.profile!.user.email!)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Active reports',
                          value: '${p.profile?.activeListings ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Stat(
                          label: 'Returns',
                          value: '${p.profile?.successfulReturns ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Edit profile'),
                          onTap: _editProfile,
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change password'),
                          onTap: _changePassword,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign out'),
                          onTap: () => auth.logout(),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Delete account',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    ),
  );
}
