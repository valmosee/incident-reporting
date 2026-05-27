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

  // ── TIDAK ada shared http.Client ─────────────────────────────────────────
  // Setiap request buat http.Client baru, langsung close setelah selesai.
  // Ini menghindari "Client is already closed" karena flutter_map tile loader
  // mempunyai lifecycle sendiri yang tidak berhubungan dengan client kita.

  bool _disposed = false; // guard: stop semua setState setelah dispose
  bool _loadingLocation = false;
  bool _loadingAddress = false;
  List _results = [];

  Timer? _searchDebounce;
  Timer? _dragDebounce;

  LatLng _markerPos = const LatLng(-7.2575, 112.7521);
  String _alamat = '';

  // ── Helper: set state hanya kalau widget masih hidup ─────────────────────
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  // ── Reverse geocode — buat & close client sendiri, ada timeout ───────────
  Future<String> _reverseGeocode(double lat, double lng) async {
    if (_disposed) return '$lat, $lng';

    try {
      if (kIsWeb) {
        final client = http.Client(); // baru tiap panggilan
        try {
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse'
            '?lat=$lat&lon=$lng&format=json&addressdetails=1',
          );
          final resp = await client
              .get(
                url,
                headers: {
                  'Accept-Language': 'id',
                  'User-Agent': 'JalanKitaApp/1.0',
                },
              )
              .timeout(const Duration(seconds: 8));

          if (!_disposed && resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final addr = data['address'] as Map<String, dynamic>? ?? {};
            final parts = <String>[
              (addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? '')
                  as String,
              (addr['suburb'] ?? addr['neighbourhood'] ?? '') as String,
              (addr['city'] ?? addr['town'] ?? addr['village'] ?? '') as String,
            ].where((e) => e.isNotEmpty).toList();
            if (parts.isNotEmpty) return parts.join(', ');
          }
        } finally {
          client.close(); // selalu close, bahkan saat exception/timeout
        }
      } else {
        // Mobile: package geocoding, tidak butuh http.Client
        final placemarks = await placemarkFromCoordinates(
          lat,
          lng,
        ).timeout(const Duration(seconds: 8));
        if (!_disposed && placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          if (parts.isNotEmpty) return parts;
        }
      }
    } on TimeoutException {
      // Timeout normal — fallback ke koordinat
    } catch (_) {
      // Semua error lain diabaikan — jangan freeze
    }

    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  // ── Pindahkan marker ke koordinat tertentu ────────────────────────────────
  Future<void> _moveToLatLng(
    double lat,
    double lng, {
    String? alamatHint,
  }) async {
    if (_disposed) return;

    _safeSetState(() {
      _markerPos = LatLng(lat, lng);
      _alamat = alamatHint ?? _alamat;
      _results = [];
      searchC.clear();
    });
    mapController.move(LatLng(lat, lng), 17);

    // Kalau alamat sudah dari search result → langsung simpan, skip geocoding
    if (alamatHint != null) {
      global.latitude = lat;
      global.longitude = lng;
      global.lokasi = alamatHint;
      return;
    }

    _safeSetState(() => _loadingAddress = true);
    final alamat = await _reverseGeocode(lat, lng);
    if (_disposed) return;

    _safeSetState(() {
      _alamat = alamat;
      _loadingAddress = false;
    });
    global.latitude = lat;
    global.longitude = lng;
    global.lokasi = alamat;
  }

  // ── Handler drag peta: marker ikut tengah, geocode debounced ─────────────
  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveEnd && event is! MapEventScrollWheelZoom) return;
    if (_disposed) return;

    final center = event.camera.center;
    _safeSetState(() => _markerPos = center);

    _dragDebounce?.cancel();
    _dragDebounce = Timer(const Duration(milliseconds: 900), () async {
      if (_disposed) return;
      _safeSetState(() => _loadingAddress = true);

      final alamat = await _reverseGeocode(center.latitude, center.longitude);
      if (_disposed) return;

      _safeSetState(() {
        _alamat = alamat;
        _loadingAddress = false;
      });
      global.latitude = center.latitude;
      global.longitude = center.longitude;
      global.lokasi = alamat;
    });
  }

  // ── Search via Photon ─────────────────────────────────────────────────────
  Future<void> _searchLocation(String keyword) async {
    if (_disposed || keyword.isEmpty) {
      _safeSetState(() => _results = []);
      return;
    }

    final client = http.Client(); // baru tiap pencarian
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(keyword)}&limit=5',
      );
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (!_disposed && response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        _safeSetState(() => _results = data['features']);
      }
    } on TimeoutException {
      // Abaikan
    } catch (_) {
      // Abaikan
    } finally {
      client.close();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      _safeSetState(() => _results = []);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _searchLocation(value),
    );
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    if (_disposed) return;
    _safeSetState(() => _loadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('GPS tidak aktif');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!_disposed && mounted) {
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
      if (perm == LocationPermission.denied) {
        _snack('Izin lokasi ditolak');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      if (_disposed) return;
      await _moveToLatLng(pos.latitude, pos.longitude);
    } on TimeoutException {
      _snack('Timeout mendapatkan lokasi GPS');
    } catch (e) {
      _snack('Gagal mendapatkan lokasi: $e');
    } finally {
      _safeSetState(() => _loadingLocation = false);
    }
  }

  // ── Konfirmasi ────────────────────────────────────────────────────────────
  void _confirmLocation() {
    global.latitude = _markerPos.latitude;
    global.longitude = _markerPos.longitude;
    global.lokasi = _alamat.isNotEmpty
        ? _alamat
        : '${_markerPos.latitude.toStringAsFixed(5)}, ${_markerPos.longitude.toStringAsFixed(5)}';
    Navigator.pop(context);
  }

  void _snack(String msg) {
    if (!_disposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
  }

  @override
  void dispose() {
    _disposed = true; // set dulu sebelum cancel timer
    _searchDebounce?.cancel();
    _dragDebounce?.cancel();
    searchC.dispose();
    // TIDAK ada _httpClient.close() di sini — semua client sudah di-close sendiri
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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

          // ── Peta ─────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _markerPos,
                    initialZoom: 17,
                    onMapEvent: _onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.jalankita.app',
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

                // Crosshair tengah
                const Center(
                  child: Icon(Icons.add, color: Colors.black38, size: 20),
                ),

                // ── Dropdown search results ───────────────────
                if (_results.isNotEmpty)
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
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = _results[i];
                            final props = item['properties'];
                            final coords = item['geometry']['coordinates'];
                            final double lon = (coords[0] as num).toDouble();
                            final double lat = (coords[1] as num).toDouble();
                            final name = props['name'] ?? '-';
                            final city = props['city'] ?? '';
                            final country = props['country'] ?? '';
                            final sub = [
                              city,
                              country,
                            ].where((s) => s.isNotEmpty).join(', ');

                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              title: Text(name),
                              subtitle: sub.isNotEmpty ? Text(sub) : null,
                              onTap: () =>
                                  _moveToLatLng(lat, lon, alamatHint: name),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // ── Alamat + tombol konfirmasi ────────────────
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _loadingAddress
                            ? Container(
                                key: const ValueKey('loading'),
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
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Mencari alamat...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _alamat.isNotEmpty
                            ? Container(
                                key: const ValueKey('address'),
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
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loadingAddress ? null : _confirmLocation,
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
                            disabledBackgroundColor: const Color(
                              0xFF1565C0,
                            ).withOpacity(0.5),
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
