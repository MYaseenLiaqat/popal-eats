import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Registration upload control — picker, filename, and preview (images only).
class RegistrationFilePicker extends StatelessWidget {
  const RegistrationFilePicker({
    super.key,
    required this.label,
    required this.file,
    required this.onFileSelected,
    this.onClear,
    this.imageOnly = true,
    this.circularPreview = false,
    this.previewHeight = 88,
  });

  final String label;
  final PlatformFile? file;
  final ValueChanged<PlatformFile> onFileSelected;
  final VoidCallback? onClear;
  final bool imageOnly;
  final bool circularPreview;
  final double previewHeight;

  bool get _isImageFile {
    final name = file?.name.toLowerCase() ?? '';
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp');
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions:
          imageOnly ? null : const ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    onFileSelected(result.files.first);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = file != null;
    final showImagePreview = hasFile && _isImageFile && file!.bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLeading(showImagePreview),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasFile ? file!.name : 'No file selected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  hasFile ? FontWeight.w600 : FontWeight.normal,
                              color: hasFile ? null : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasFile && file!.size > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatSize(file!.size),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasFile && onClear != null)
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: onClear,
                        icon: const Icon(Icons.close, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: Text(hasFile ? 'Change' : 'Upload'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showImagePreview && !circularPreview) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: previewHeight,
              width: double.infinity,
              child: Image.memory(file!.bytes!, fit: BoxFit.cover),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeading(bool showImagePreview) {
    if (showImagePreview && circularPreview) {
      return ClipOval(
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.memory(file!.bytes!, fit: BoxFit.cover),
        ),
      );
    }
    if (showImagePreview) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.memory(file!.bytes!, fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        imageOnly ? Icons.image_outlined : Icons.description_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Backward-compatible alias for image-only uploads.
typedef RegistrationImagePicker = RegistrationFilePicker;
