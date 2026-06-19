import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/device_location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';

/// Explains location use before the OS permission prompt.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _loading = false;

  Future<void> _enableLocation() async {
    setState(() => _loading = true);
    try {
      await DeviceLocationService().getCurrentPosition();
    } catch (_) {
      // User may deny — still mark onboarding complete.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        widget.onCompleted();
      }
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.location_on_outlined, size: 56, color: AppColors.gold),
              const SizedBox(height: 16),
              Text(
                'Find food near you',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Location helps Popal Eats suggest nearby restaurants and improves group recommendations when you share your spot with friends.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              const ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bullet('Only used when you opt in — e.g. group sessions'),
                    SizedBox(height: 8),
                    _Bullet('Never shared publicly on your profile'),
                    SizedBox(height: 8),
                    _Bullet('You can change this anytime in device settings'),
                  ],
                ),
              ),
              const Spacer(),
              GoldActionButton(
                label: 'Enable Location',
                icon: Icons.my_location_outlined,
                loading: _loading,
                onPressed: _loading ? null : _enableLocation,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loading ? null : widget.onCompleted,
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: _openSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.green, fontSize: 16)),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
