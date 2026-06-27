import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Create a recipe post with ingredients and steps.
class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _content = ContentService();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _caption = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _videoUrl = TextEditingController();

  PlatformFile? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _caption.dispose();
    _ingredients.dispose();
    _steps.dispose();
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

  List<String> _lines(TextEditingController c) {
    return c.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final body = Post(
        id: 0,
        authorId: 0,
        postType: PostType.recipe,
        title: _title.text.trim(),
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        recipeDescription: _description.text.trim().isEmpty ? null : _description.text.trim(),
        recipeIngredients: _lines(_ingredients),
        recipeSteps: _lines(_steps),
        videoUrl: _videoUrl.text.trim().isEmpty ? null : _videoUrl.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share recipe'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
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
              height: 160,
              child: _image?.bytes != null
                  ? Image.memory(_image!.bytes!, fit: BoxFit.cover)
                  : const Center(child: Text('Add recipe photo')),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Recipe title *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caption,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Caption'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ingredients,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Ingredients (one per line)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _steps,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Steps (one per line)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoUrl,
            decoration: const InputDecoration(
              labelText: 'Video URL (optional)',
            ),
          ),
        ],
      ),
    );
  }
}
