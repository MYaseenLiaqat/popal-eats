import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Restaurant profile tab — edit business details and sign out.
class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({
    super.key,
    required this.restaurantId,
    this.onRestaurantUpdated,
  });

  final int restaurantId;
  final VoidCallback? onRestaurantUpdated;

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _service = RestaurantOwnerService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _opening = TextEditingController();
  final _closing = TextEditingController();
  final _cuisine = TextEditingController();

  bool _isOpen = true;
  String? _imageUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RestaurantProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _opening.dispose();
    _closing.dispose();
    _cuisine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final restaurant = await _service.getRestaurant(widget.restaurantId);
      if (!mounted) return;
      _name.text = restaurant.name;
      _description.text = restaurant.description ?? '';
      _address.text = restaurant.address ?? '';
      _city.text = restaurant.city ?? '';
      _phone.text = restaurant.phoneNumber ?? '';
      _opening.text = restaurant.openingTime ?? '';
      _closing.text = restaurant.closingTime ?? '';
      _cuisine.text = restaurant.tags.join(', ');
      setState(() {
        _isOpen = restaurant.isOpen;
        _imageUrl = restaurant.image;
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
      final tags = _cuisine.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await _service.updateRestaurant(widget.restaurantId, {
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'phone_number': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'opening_time': _opening.text.trim().isEmpty ? null : _opening.text.trim(),
        'closing_time': _closing.text.trim().isEmpty ? null : _closing.text.trim(),
        'is_open': _isOpen,
        if (tags.isNotEmpty) 'tags': tags,
      });
      widget.onRestaurantUpdated?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant profile updated')),
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

  Future<void> _uploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
    try {
      final updated = await _service.uploadRestaurantImage(
        restaurantId: widget.restaurantId,
        bytes: file.bytes!,
        filename: file.name,
      );
      setState(() => _imageUrl = updated.image);
      widget.onRestaurantUpdated?.call();
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

    final resolvedImage = _resolveImageUrl(_imageUrl);

    return ListView(
      padding: const EdgeInsets.all(AppColors.screenPadding),
      children: [
        Center(
          child: GestureDetector(
            onTap: _uploadLogo,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundImage:
                  resolvedImage != null ? NetworkImage(resolvedImage) : null,
              child: resolvedImage == null
                  ? const Icon(Icons.store, size: 40, color: AppColors.accent)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: _uploadLogo, child: const Text('Upload logo')),
        ),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Restaurant name')),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 12),
        TextField(
          controller: _opening,
          decoration: const InputDecoration(
            labelText: 'Opening hours',
            hintText: '09:00:00',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _closing,
          decoration: const InputDecoration(
            labelText: 'Closing hours',
            hintText: '22:00:00',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cuisine,
          decoration: const InputDecoration(
            labelText: 'Cuisine tags',
            hintText: 'Italian, Pizza',
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Open for orders'),
          value: _isOpen,
          onChanged: (v) => setState(() => _isOpen = v),
        ),
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
