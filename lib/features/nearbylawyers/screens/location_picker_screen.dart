import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen map that lets the user choose a search location manually:
/// tap anywhere to drop a pin, then confirm. Returns the picked [LatLng]
/// via [Get.back] — no GPS is touched anywhere in this flow.
class LocationPickerScreen extends StatefulWidget {
  /// Where to center the map initially (e.g. the current search location).
  final LatLng? initialCenter;

  const LocationPickerScreen({super.key, this.initialCenter});

  /// Convenience helper: pushes the picker and returns the picked point,
  /// or null if the user backed out.
  static Future<LatLng?> open({LatLng? initialCenter}) async {
    return Get.to<LatLng>(
      () => LocationPickerScreen(initialCenter: initialCenter),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _picked;

  // Default center: Dar es Salaam, Tanzania (app's home market)
  static const LatLng _defaultCenter = LatLng(-6.7924, 39.2083);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = widget.initialCenter ?? _picked ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
              onTap: (_, latLng) {
                setState(() {
                  _picked = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'co.tz.pola.app',
                maxZoom: 19,
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _picked!,
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar: back button + instruction
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      tr('Tap the map to choose your location'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm button
          if (_picked != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: FloatingActionButton.extended(
                  heroTag: 'confirm_location_button',
                  backgroundColor: theme.colorScheme.primary,
                  onPressed: () => Get.back(result: _picked),
                  icon: Icon(Icons.check,
                      color: theme.colorScheme.onPrimary),
                  label: Text(
                    tr('Use this location'),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
