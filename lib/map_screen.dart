import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'سرویس موقعیت مکانی غیرفعال است.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'دسترسی به موقعیت مکانی رد شد.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'دسترسی برای همیشه رد شده است.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در دریافت موقعیت: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = _currentPosition ?? const LatLng(35.6892, 51.3890);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقشه'),
      ),
      body: _currentPosition == null && _errorMessage.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: initialCenter,
                    zoom: 15,
                    onMapReady: () {
                      if (_currentPosition != null) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _mapController.move(_currentPosition!, 15);
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'http://10.100.252.137:8080/tile/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.map',
                    ),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: _currentPosition!,
                            builder: (_) => const Icon(
                              Icons.location_pin,
                              size: 40,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
    );
  }
}
