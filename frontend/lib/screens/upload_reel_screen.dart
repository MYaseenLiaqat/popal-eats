import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Customer reel upload — food post with video.
class UploadReelScreen extends StatefulWidget {
  const UploadReelScreen({super.key});

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  final _content = ContentService();
  final _caption = TextEditingController();
  final _restaurantId = TextEditingController();

  PlatformFile? _video;
  PlatformFile? _thumbnail;
  bool _submitting = false;

  @override
  void dispose() {
    _caption.dispose();
    _restaurantId.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _video = result.files.first);
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _thumbnail = result.files.first);
  }

  Future<void> _submit() async {
    if (_video?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a video to upload')),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final body = Post(
        id: 0,
        authorId: 0,
        postType: PostType.foodPost,
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        restaurantId: int.tryParse(_restaurantId.text.trim()),
      ).toWriteJson();

      var post = await _content.createPost(body);
      post = await _content.uploadPostVideo(
        postId: post.id,
        bytes: _video!.bytes!,
        filename: _video!.name,
      );

      if (_thumbnail?.bytes != null) {
        post = await _content.uploadPostImage(
          postId: post.id,
          bytes: _thumbnail!.bytes!,
          filename: _thumbnail!.name,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
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
        title: const Text('Upload reel'),
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
            onTap: _pickVideo,
            child: SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_outlined, size: 48, color: AppColors.accent),
                    const SizedBox(height: 8),
                    Text(
                      _video?.name ?? 'Tap to select video',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ModernCard(
            onTap: _pickThumbnail,
            child: SizedBox(
              height: 120,
              child: _thumbnail?.bytes != null
                  ? Image.memory(_thumbnail!.bytes!, fit: BoxFit.cover)
                  : const Center(child: Text('Optional cover image')),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Describe your food experience',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _restaurantId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Restaurant ID (optional tag)',
            ),
          ),
        ],
      ),
    );
  }
}
