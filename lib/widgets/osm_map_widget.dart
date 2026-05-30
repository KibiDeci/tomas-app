import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMapWidget extends StatelessWidget {
  final LatLng? center;
  final List<Marker>? markers;
  const OsmMapWidget({super.key, this.center, this.markers});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: center ?? const LatLng(-7.5585, 110.8317), // Surakarta default
        zoom: 14,
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
