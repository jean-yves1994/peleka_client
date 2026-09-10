import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../data/location_repository.dart';

class LocationVerificationMap extends StatefulWidget {
  final PlaceResult candidate;
  final String title;
  final String subtitle;
  final Future<PlaceResult?> Function(double lat, double lng) onReverse;
  final void Function(double lat, double lng, double? accuracyMeters) onChanged;

  const LocationVerificationMap({
    super.key,
    required this.candidate,
    required this.title,
    required this.subtitle,
    required this.onReverse,
    required this.onChanged,
  });

  @override
  State<LocationVerificationMap> createState() =>
      _LocationVerificationMapState();
}

class _LocationVerificationMapState extends State<LocationVerificationMap> {
  late final MapController _mapController;

  late LatLng _point;
  PlaceResult? _resolved;

  bool _resolving = false;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();

    _point = LatLng(
      widget.candidate.lat,
      widget.candidate.lng,
    );

    _resolved = widget.candidate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onChanged(
        _point.latitude,
        _point.longitude,
        widget.candidate.accuracyMeters,
      );
    });
  }

  Future<void> _resolveLocation(LatLng point) async {
    if (!mounted) return;

    setState(() {
      _point = point;
      _resolving = true;
    });

    // Immediately notify the parent of the new coordinates.
    widget.onChanged(
      point.latitude,
      point.longitude,
      null,
    );

    try {
      final place = await widget.onReverse(
        point.latitude,
        point.longitude,
      );

      if (!mounted) return;

      if (place != null) {
        setState(() {
          _resolved = place;
        });
      }
    } catch (_) {
      // Keep the selected coordinates even when reverse
      // geocoding temporarily fails.
    } finally {
      if (!mounted) return;

      setState(() {
        _resolving = false;
      });
    }
  }

  void _handleMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final LatLng center = event.camera.center;

      _resolveLocation(center);
    }
  }

  void _moveToPoint(LatLng point) {
    _mapController.move(
      point,
      _mapController.camera.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String label = (_resolved?.address.isNotEmpty == true)
        ? _resolved!.address
        : (_resolved?.name.isNotEmpty == true
            ? _resolved!.name
            : 'Selected location');

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Map
        SizedBox(
          height: 360,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _point,
                  initialZoom: 16,

                  // Listen for completed map movement.
                  onMapEvent: _handleMapEvent,

                  // Tapping anywhere on the map moves
                  // the center pin to that location.
                  onTap: (_, point) {
                    _moveToPoint(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.peleka_customer',
                  ),
                  RichAttributionWidget(
                    attributions: const [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),

              // Fixed center pin.
              //
              // The map moves underneath this pin.
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -26),
                      child: const Icon(
                        Icons.location_pin,
                        size: 52,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ),

              // Instruction badge.
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: AppColors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Move the map to position the pin on the exact location.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Selected address.
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (_resolving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
