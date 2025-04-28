import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final String token;

  const MapScreen({super.key, required this.token});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  String _errorMessage = '';
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startListeningLocation();
  }

  Future<void> _startListeningLocation() async {
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

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // هر 10 متر تغییر، گزارش داده شود
        ),
      ).listen((Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentPosition = newPosition;
        });

        // موقعیت جدید را به سرور ارسال کن
        sendLocationToServer(newPosition);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در دریافت موقعیت: $e';
      });
    }
  }

  Future<void> sendLocationToServer(LatLng position) async {
    final url = Uri.parse('http://192.168.2.100:8000/api/location');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('موقعیت جدید با موفقیت ارسال شد.');
      } else {
        debugPrint('خطا در ارسال موقعیت: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('خطا در ارسال: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // مهم! استریم باید بسته شود
    super.dispose();
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
