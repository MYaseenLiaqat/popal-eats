import 'package:flutter/material.dart';

/// OCR menu upload screen — wire file_picker in production.
class MenuUploadScreen extends StatelessWidget {
  const MenuUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Menu (OCR)')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload a menu image to extract dishes.'),
            SizedBox(height: 12),
            Text('API: POST /menu/import'),
            SizedBox(height: 12),
            Text('Use MenuService.importMenu() with restaurant + category IDs.'),
            SizedBox(height: 24),
            Text('Preview imported items before confirming in a future build.'),
          ],
        ),
      ),
    );
  }
}
