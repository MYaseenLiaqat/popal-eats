import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../utils/media_url.dart';

/// Full-screen story viewer with tap-to-advance.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.group,
    this.initialIndex = 0,
  });

  final StoryGroup group;
  final int initialIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final _content = ContentService();
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.group.stories.length - 1);
    _markViewed(widget.group.stories[_index]);
  }

  Future<void> _markViewed(StoryItem story) async {
    try {
      await _content.markStoryViewed(story.id);
    } catch (_) {}
  }

  void _next() {
    if (_index < widget.group.stories.length - 1) {
      setState(() => _index++);
      _markViewed(widget.group.stories[_index]);
    } else {
      Navigator.pop(context);
    }
  }

  void _previous() {
    if (_index > 0) {
      setState(() => _index--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.group.stories[_index];
    final imageUrl = resolveMediaUrl(story.imageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.localPosition.dx < width * 0.35) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, fit: BoxFit.contain)
            else
              const Center(child: Icon(Icons.image_not_supported, color: Colors.white54)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.group.user.fullName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${_index + 1}/${widget.group.stories.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.group.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick image and upload a new story.
Future<bool?> showCreateStorySheet(BuildContext context) async {
  final content = ContentService();
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return false;
  final file = result.files.first;
  if (file.bytes == null) return false;

  if (!context.mounted) return false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    ),
  );

  try {
    await content.createStory(bytes: file.bytes!, filename: file.name);
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story shared — visible for 24 hours')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
    return false;
  }
}
