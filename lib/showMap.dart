import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'global.dart' as global;

class Showmap extends StatefulWidget {
  const Showmap({super.key});

  @override
  State<Showmap> createState() => _ShowmapState();
}

class _ShowmapState extends State<Showmap> {
  final TextEditingController searchC = TextEditingController();
  final MapController mapController = MapController();

  bool _loadingLocation = false;
  List results = [];
  Timer? debounce;

  // Posisi awal: Surabaya
  LatLng _markerPos = const LatLng(-7.2575, 112.7521);
  String _alamat = '';

  // ── Pindahkan marker + map ke koordinat tertentu ──────────────────────────
  void _moveToLatLng(double lat, double lng, String alamat) {
    setState(() {
      _markerPos = LatLng(lat, lng);
      _alamat = alamat;
      results = []; // tutup dropdown
      searchC.clear();
    });
    mapController.move(LatLng(lat, lng), 17);
  }

  // ── Cari lokasi via Photon (debounce 500 ms) ──────────────────────────────
  Future<void> _searchLocation(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => results = []);
      return;
    }
    final url = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(keyword)}&limit=5',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => results = data['features']);
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(
      const Duration(milliseconds: 500),
      () => _searchLocation(value),
    );
  }

  // ── Ambil lokasi GPS (pola dari contoh getLocation()) ────────────────────
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);

    try {
      // 1. Cek GPS aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('GPS tidak aktif');
        return;
      }

      // 2. Cek & minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission ditolak permanen'),
              action: SnackBarAction(
                label: 'Buka Pengaturan',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        _snack('Izin lokasi ditolak');
        return;
      }

      // 3. Ambil posisi — pakai desiredAccuracy seperti contoh
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // debug info (sama seperti contoh)
      print('Lat: ${position.latitude}');
      print('Lng: ${position.longitude}');
      print('Accuracy: ${position.accuracy}');
      print('Altitude: ${position.altitude}');
      print('Speed: ${position.speed}');
      print('Heading: ${position.heading}');
      print('Timestamp: ${position.timestamp}');

      // 4 + 5. Reverse geocoding → alamat teks (bukan koordinat)
      // Fallback awal: koordinat (dipakai jika geocoding gagal)
      String alamat =
          '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';

      try {
        if (kIsWeb) {
          // Web TIDAK support package geocoding → pakai Nominatim HTTP
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse'
            '?lat=${position.latitude}&lon=${position.longitude}'
            '&format=json&addressdetails=1',
          );
          final resp = await http.get(
            url,
            headers: {'Accept-Language': 'id', 'User-Agent': 'FlutterApp/1.0'},
          );
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final addr = data['address'] as Map<String, dynamic>? ?? {};
            final parts = <String>[
              (addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? '')
                  as String,
              (addr['suburb'] ?? addr['neighbourhood'] ?? '') as String,
              (addr['city'] ?? addr['town'] ?? addr['village'] ?? '') as String,
              (addr['county'] ?? '') as String,
            ].where((e) => e.isNotEmpty).toList();
            if (parts.isNotEmpty) alamat = parts.join(', ');
          }
        } else {
          // Mobile (Android/iOS): pakai package geocoding, null-safe
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            print('Street   : ${p.street ?? "-"}');
            print('Locality : ${p.locality ?? "-"}');
            print('Country  : ${p.country ?? "-"}');
            final parts = [
              p.street,
              p.subLocality,
              p.locality,
              p.subAdministrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            if (parts.isNotEmpty) alamat = parts;
          }
        }
      } catch (geoErr) {
        // Geocoding gagal → tetap pakai fallback koordinat
        print('Geocoding error (diabaikan): $geoErr');
      }

      // 6. Simpan ke global
      global.latitude = position.latitude;
      global.longitude = position.longitude;
      global.lokasi = alamat;

      // 7. Update marker & pindahkan map (setState seperti contoh)
      if (mounted) {
        setState(() {
          _markerPos = LatLng(position.latitude, position.longitude);
          _alamat = alamat;
          results = [];
          searchC.clear();
        });
        mapController.move(LatLng(position.latitude, position.longitude), 18);
      }
    } catch (e) {
      _snack('Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── Konfirmasi pilihan lokasi → kembali ke CreateReport ──────────────────
  void _confirmLocation() {
    // Pastikan global sudah ter-set (jika user tidak ketuk item list / GPS)
    global.latitude = _markerPos.latitude;
    global.longitude = _markerPos.longitude;
    if (global.lokasi.isEmpty) {
      global.lokasi =
          '${_markerPos.latitude.toStringAsFixed(5)}, '
          '${_markerPos.longitude.toStringAsFixed(5)}';
    }
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    // Tunggu frame pertama selesai agar mapController sudah siap
    // sebelum memanggil mapController.move() di dalam _getCurrentLocation()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol GPS
          _loadingLocation
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  tooltip: 'Gunakan lokasi GPS',
                  onPressed: _getCurrentLocation,
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: searchC,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari lokasi...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A2D42),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Peta + dropdown hasil pencarian ───────────────
          Expanded(
            child: Stack(
              children: [
                // Peta
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _markerPos,
                    initialZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPos,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Dropdown hasil pencarian (overlay di atas peta)
                if (results.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            final props = item['properties'];
                            final coords = item['geometry']['coordinates'];
                            final double lon = (coords[0] as num).toDouble();
                            final double lat = (coords[1] as num).toDouble();

                            final name = props['name'] ?? '-';
                            final country = props['country'] ?? '';
                            final city = props['city'] ?? '';
                            final subtitle = [
                              city,
                              country,
                            ].where((s) => s.isNotEmpty).join(', ');

                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              title: Text(name),
                              subtitle: subtitle.isNotEmpty
                                  ? Text(subtitle)
                                  : null,
                              onTap: () {
                                // Simpan ke global
                                global.latitude = lat;
                                global.longitude = lon;
                                global.lokasi = name;

                                // Gerakkan marker & peta
                                _moveToLatLng(lat, lon, name);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Tombol "Pilih Lokasi Ini" di bawah peta
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Label alamat terpilih
                      if (_alamat.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _alamat,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Pilih Lokasi Ini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
