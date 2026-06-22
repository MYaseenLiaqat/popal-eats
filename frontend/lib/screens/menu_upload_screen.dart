import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// OCR menu upload screen — developer-only; not linked in customer navigation.
class MenuUploadScreen extends StatelessWidget {
  const MenuUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import Menu')),
        body: const Center(child: Text('This feature is not available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import Menu (OCR)')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Developer tool — upload a menu image to extract dishes.'),
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
