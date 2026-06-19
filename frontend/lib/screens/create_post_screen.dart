import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Create a food post with image, caption, and optional tags.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _content = ContentService();
  final _caption = TextEditingController();
  final _restaurantId = TextEditingController();
  final _dishId = TextEditingController();

  PlatformFile? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _caption.dispose();
    _restaurantId.dispose();
    _dishId.dispose();
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
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final body = Post(
        id: 0,
        authorId: 0,
        postType: PostType.foodPost,
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        restaurantId: int.tryParse(_restaurantId.text.trim()),
        dishId: int.tryParse(_dishId.text.trim()),
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
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New food post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : const Text('Share'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            onTap: _pickImage,
            child: SizedBox(
              height: 200,
              child: _image?.bytes != null
                  ? Image.memory(_image!.bytes!, fit: BoxFit.cover)
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.gold),
                          SizedBox(height: 8),
                          Text('Tap to add food photo'),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'What did you eat?',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _restaurantId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Restaurant ID (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dishId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Dish ID (optional)',
            ),
          ),
        ],
      ),
    );
  }
}
