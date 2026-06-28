import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/restaurant.dart';
import '../services/content_service.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Restaurant owner: promotions, new dishes, announcements.
class RestaurantPostScreen extends StatefulWidget {
  const RestaurantPostScreen({
    super.key,
    this.restaurantId,
    this.initialSubtype,
    this.reelMode = false,
  });

  final int? restaurantId;
  final String? initialSubtype;
  final bool reelMode;

  @override
  State<RestaurantPostScreen> createState() => _RestaurantPostScreenState();
}

class _RestaurantPostScreenState extends State<RestaurantPostScreen> {
  final _content = ContentService();
  final _owner = RestaurantOwnerService();
  final _caption = TextEditingController();
  final _title = TextEditingController();
  final _videoUrl = TextEditingController();

  List<Restaurant> _restaurants = [];
  Restaurant? _selected;
  late RestaurantContentSubtype _subtype;
  PlatformFile? _image;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _subtype = _parseSubtype(widget.initialSubtype);
    _loadRestaurants();
  }

  RestaurantContentSubtype _parseSubtype(String? value) {
    switch (value) {
      case 'new_dish':
        return RestaurantContentSubtype.newDish;
      case 'announcement':
        return RestaurantContentSubtype.announcement;
      default:
        return RestaurantContentSubtype.promotion;
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final list = await _owner.listMine();
      if (!mounted) return;
      setState(() {
        _restaurants = list;
        _selected = widget.restaurantId != null
            ? list.where((r) => r.id == widget.restaurantId).firstOrNull
            : (list.isNotEmpty ? list.first : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _title.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _image = result.files.first);
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a restaurant')),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final body = Post(
        id: 0,
        authorId: 0,
        postType: PostType.restaurantPost,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        restaurantId: _selected!.id,
        restaurantContentSubtype: _subtype,
        videoUrl: widget.reelMode && _videoUrl.text.trim().isNotEmpty
            ? _videoUrl.text.trim()
            : null,
      ).toWriteJson();

      var post = await _content.createPost(body);

      if (_image?.bytes != null) {
        post = await _content.uploadPostImage(
          postId: post.id,
          bytes: _image!.bytes!,
          filename: _image!.name,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reelMode ? 'Restaurant reel' : 'Restaurant post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          if (_restaurants.isEmpty)
            const ModernCard(
              child: EmptyState(
                icon: Icons.store_outlined,
                title: 'No restaurant found',
                subtitle: 'Register and get approved before posting.',
              ),
            )
          else ...[
            DropdownButtonFormField<Restaurant>(
              value: _selected,
              decoration: const InputDecoration(labelText: 'Restaurant'),
              items: _restaurants
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (r) => setState(() => _selected = r),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RestaurantContentSubtype>(
              value: _subtype,
              decoration: const InputDecoration(labelText: 'Post type'),
              items: const [
                DropdownMenuItem(
                  value: RestaurantContentSubtype.promotion,
                  child: Text('Promotion'),
                ),
                DropdownMenuItem(
                  value: RestaurantContentSubtype.newDish,
                  child: Text('New dish'),
                ),
                DropdownMenuItem(
                  value: RestaurantContentSubtype.announcement,
                  child: Text('Announcement'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _subtype = v);
              },
            ),
            const SizedBox(height: 12),
            if (widget.reelMode) ...[
              TextField(
                controller: _videoUrl,
                decoration: const InputDecoration(
                  labelText: 'Video URL (reel)',
                  hintText: 'https://…',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Headline'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
            const SizedBox(height: 12),
            ModernCard(
              onTap: _pickImage,
              child: SizedBox(
                height: 160,
                child: _image?.bytes != null
                    ? Image.memory(_image!.bytes!, fit: BoxFit.cover)
                    : const Center(child: Text('Add image')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
