import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../widgets/osm_map_widget.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _picked;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
    if (_picked == null) _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _loading = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _picked = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi di Peta')),
      body: Stack(
        children: [
          OsmMapWidget(
            center: _picked,
            markers: _picked == null
                ? null
                : [
                    Marker(
                      point: _picked!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _picked == null
            ? null
            : () => Navigator.pop(context, _picked),
        label: const Text('Pilih Lokasi Ini'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
