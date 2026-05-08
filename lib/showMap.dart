import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Showmap extends StatefulWidget {
  const Showmap({super.key});

  @override
  State<Showmap> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Showmap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OpenStreetMap')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-7.2575, 112.7521), // Surabaya
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),

          // marker
          const MarkerLayer(
            markers: [
              Marker(
                point: LatLng(-7.2575, 112.7521),
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
