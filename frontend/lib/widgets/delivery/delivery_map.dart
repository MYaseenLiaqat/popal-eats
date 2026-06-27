import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/google_maps_web_loader.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_colors.dart';
import 'delivery_constants.dart';

/// Google Maps delivery view with demo coordinates and animated rider marker.
///
/// Replace [coordinates] with live backend lat/lng when available.
class DeliveryMap extends StatefulWidget {
  const DeliveryMap({
    super.key,
    required this.coordinates,
    required this.routeProgress,
    this.heightFactor = 0.45,
  });

  final DeliveryCoordinates coordinates;
  final double routeProgress;
  final double heightFactor;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  bool _mapReady = false;
  bool _mapFailed = false;
  Timer? _loadTimeout;
  late AnimationController _fade;
  late Animation<double> _fadeAnim;
  LatLng _riderPosition = const LatLng(0, 0);

  bool get _canUseGoogleMap => !kIsWeb || GoogleMapsWebLoader.isAvailable;

  @override
  void initState() {
    super.initState();
    _riderPosition = widget.coordinates.rider;
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    if (_canUseGoogleMap) {
      _loadTimeout = Timer(const Duration(seconds: 10), () {
        if (!mounted || _mapReady) return;
        setState(() => _mapFailed = true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant DeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeProgress != widget.routeProgress) {
      _animateRider(widget.coordinates.withRiderProgress(widget.routeProgress).rider);
    }
  }

  Future<void> _animateRider(LatLng target) async {
    final start = _riderPosition;
    const steps = 24;
    for (var i = 1; i <= steps; i++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      setState(() {
        _riderPosition = LatLng(
          start.latitude + (target.latitude - start.latitude) * (i / steps),
          start.longitude + (target.longitude - start.longitude) * (i / steps),
        );
      });
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _fade.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _retryMap() async {
    setState(() => _mapFailed = false);
    if (kIsWeb) {
      await GoogleMapsWebLoader.ensureLoaded(force: true);
    }
    if (!mounted) return;
    setState(() {});
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('restaurant'),
        position: widget.coordinates.restaurant,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: widget.coordinates.customer,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Rider'),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [widget.coordinates.restaurant, widget.coordinates.customer],
        color: AppColors.accent,
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(8)],
      ),
    };
  }

  LatLng _center() {
    final r = widget.coordinates.restaurant;
    final c = widget.coordinates.customer;
    return LatLng((r.latitude + c.latitude) / 2, (r.longitude + c.longitude) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * widget.heightFactor;
    final mapHeight = height.clamp(220.0, 520.0);

    if (!_canUseGoogleMap || _mapFailed) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: _MapFallback(
              coordinates: widget.coordinates,
              riderProgress: widget.routeProgress,
              onRetry: kIsWeb ? _retryMap : null,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: mapHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _center(), zoom: 14.2),
                  markers: _buildMarkers(),
                  polylines: _buildPolylines(),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  style: _darkMapStyle,
                  onMapCreated: (controller) {
                    _controller = controller;
                    _loadTimeout?.cancel();
                    setState(() => _mapReady = true);
                    _fade.forward();
                  },
                ),
              ),
              if (!_mapReady)
                const ColoredBox(
                  color: AppColors.surfaceLight,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]}
]''';
}

/// Premium fallback map when Google Maps API key is unavailable.
class _MapFallback extends StatelessWidget {
  const _MapFallback({
    required this.coordinates,
    required this.riderProgress,
    this.onRetry,
  });

  final DeliveryCoordinates coordinates;
  final double riderProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D2B1A),
            AppColors.surfaceLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(progress: riderProgress),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _MapLegendDot(color: AppColors.accent, label: 'Restaurant'),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _MapLegendDot(color: Colors.blueAccent, label: 'You'),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.delivery_dining, color: Colors.orangeAccent.withValues(alpha: 0.9), size: 32),
                const SizedBox(height: 4),
                Text(
                  'Live map preview',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Retry map')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendDot extends StatelessWidget {
  const _MapLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.2, size.height * 0.72);
    final end = Offset(size.width * 0.78, size.height * 0.28);
    final rider = Offset.lerp(start, end, progress)!;

    final routePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.15, end.dx, end.dy);
    canvas.drawPath(path, routePaint);

    _drawPin(canvas, start, AppColors.accent);
    _drawPin(canvas, end, Colors.blueAccent);
    _drawPin(canvas, rider, Colors.orangeAccent, radius: 10);
  }

  void _drawPin(Canvas canvas, Offset center, Color color, {double radius = 8}) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
