import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/home_chef_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Home chef profile tab.
class HomeChefProfileScreen extends StatefulWidget {
  const HomeChefProfileScreen({super.key, this.onProfileUpdated});

  final VoidCallback? onProfileUpdated;

  @override
  State<HomeChefProfileScreen> createState() => _HomeChefProfileScreenState();
}

class _HomeChefProfileScreenState extends State<HomeChefProfileScreen> {
  final _service = HomeChefOwnerService();
  final _displayName = TextEditingController();
  final _cuisine = TextEditingController();
  final _address = TextEditingController();
  final _license = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _cuisine.dispose();
    _address.dispose();
    _license.dispose();
    _bio.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _service.getMe();
      if (!mounted) return;
      _displayName.text = me['display_name']?.toString() ?? '';
      _cuisine.text = me['cuisine_specialty']?.toString() ?? '';
      _address.text = me['kitchen_address']?.toString() ?? '';
      _license.text = me['food_license']?.toString() ?? '';
      _bio.text = me['biography']?.toString() ?? '';
      _phone.text = me['phone']?.toString() ?? '';
      setState(() {
        _imageUrl = me['profile_image']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateProfile({
        'display_name': _displayName.text.trim(),
        'cuisine_specialty': _cuisine.text.trim(),
        'kitchen_address': _address.text.trim(),
        'food_license': _license.text.trim().isEmpty ? null : _license.text.trim(),
        'biography': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      });
      widget.onProfileUpdated?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
    try {
      final updated = await _service.uploadProfileImage(
        bytes: file.bytes!,
        filename: file.name,
      );
      setState(() => _imageUrl = updated['profile_image']?.toString());
      widget.onProfileUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final resolved = _resolveImageUrl(_imageUrl);

    return ListView(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        Center(
          child: GestureDetector(
            onTap: _uploadImage,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundImage: resolved != null ? NetworkImage(resolved) : null,
              child: resolved == null
                  ? const Icon(Icons.person, size: 40, color: AppColors.accent)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: _uploadImage, child: const Text('Upload profile picture'))),
        const SizedBox(height: 16),
        TextField(controller: _displayName, decoration: const InputDecoration(labelText: 'Display name')),
        const SizedBox(height: 12),
        TextField(controller: _cuisine, decoration: const InputDecoration(labelText: 'Cuisine specialty')),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Kitchen address')),
        const SizedBox(height: 12),
        TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Biography')),
        const SizedBox(height: 12),
        TextField(controller: _license, decoration: const InputDecoration(labelText: 'Food license')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Contact number')),
        const SizedBox(height: 16),
        GoldActionButton(
          label: _saving ? 'Saving…' : 'Save changes',
          icon: Icons.save_outlined,
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
