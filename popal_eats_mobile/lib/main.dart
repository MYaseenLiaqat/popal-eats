import 'dart:async';

import 'package:flutter/material.dart';
import 'package:popal_eats_mobile/screens/recommendations_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[ErrorWidget] ${details.exceptionAsString()}');
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'UI build error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SelectableText(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runZonedGuarded(
    () => runApp(const PopalEatsApp()),
    (error, stack) {
      debugPrint('[ZoneError] $error\n$stack');
    },
  );
}

class PopalEatsApp extends StatelessWidget {
  const PopalEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Popal Eats',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const RecommendationsScreen(),
    );
  }
}
