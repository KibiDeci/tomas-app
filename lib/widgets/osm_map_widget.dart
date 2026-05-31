import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMapWidget extends StatelessWidget {
  final LatLng? center;
  final List<Marker>? markers;
  final void Function(TapPosition, LatLng)? onTap;
  final MapController? controller;

  const OsmMapWidget({
    super.key,
    this.center,
    this.markers,
    this.onTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter = center ?? const LatLng(-7.5585, 110.8317);

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.tomas.tomas_app',
        ),
        if (markers != null && markers!.isNotEmpty)
          MarkerLayer(markers: markers!),
      ],
    );
  }
}
