import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // برای try-catch و مدیریت خطا

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OSM Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapHomePage(title: 'Flutter OSM Map'),
    );
  }
}

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key, required this.title});
  final String title;

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    if (mounted) {
      setState(() {
        _errorMessage = '';
      });
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        if (mounted) {
          setState(() {
            _errorMessage = 'سرویس موقعیت مکانی غیرفعال است. لطفاً آن را روشن کنید.';
          });
        }
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied. Requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied by user.');
          if (mounted) {
            setState(() {
              _errorMessage = 'دسترسی به موقعیت مکانی رد شد.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        if (mounted) {
          setState(() {
            _errorMessage = 'دسترسی به موقعیت مکانی برای همیشه رد شده است. لطفاً از تنظیمات برنامه فعال کنید.';
          });
        }
        return;
      }

      print('Fetching current location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Location fetched: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _errorMessage = '';
        });
        print('State updated with current location.');
      }

    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در دریافت موقعیت مکانی: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // مقدار پیش‌فرض برای مرکز نقشه در صورت عدم دریافت موقعیت اولیه
    final LatLng initialCenter = _currentPosition ?? const LatLng(35.6892, 51.3890); // تهران

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getLocation,
            tooltip: 'دریافت مجدد موقعیت',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: initialCenter, // استفاده از مقدار اولیه یا فعلی
              zoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              // اگر موقعیت اولیه داریم، نقشه را به آنجا منتقل کن
              onMapReady: () {
                if (_currentPosition != null) {
                  // کمی تاخیر برای اطمینان از لود شدن اولیه نقشه
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) { // دوباره چک کن ویجت هنوز هست
                      _mapController.move(_currentPosition!, 15.0);
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'http://10.100.252.137:8080/tile/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                // !!! مهم: این مقدار را با نام پکیج واقعی برنامه خود جایگزین کنید !!!
                userAgentPackageName: 'com.example.map', // <-- اینجا را تغییر دهید
              ),
              if (_currentPosition != null) // مارکر را فقط اگر موقعیت داریم نشان بده
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _currentPosition!,
                      // ******** اصلاح شده ********
                      builder: (ctx) => const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                      // ******** /اصلاح شده ********
                    ),
                  ],
                ),
            ],
          ),

          // نمایش لودینگ فقط در زمان اولیه و نبود خطا
          if (_currentPosition == null && _errorMessage.isEmpty)
            const Center(child: CircularProgressIndicator()),

          // نمایش پیام خطا در صورت وجود
          if (_errorMessage.isNotEmpty)
            Positioned.fill( // تمام صفحه را بگیرد
              child: Container( // پس‌زمینه نیمه‌شفاف برای خوانایی بهتر
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container( // کادر برای پیام خطا
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            spreadRadius: 1)
                      ],
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 15.0); // حرکت به موقعیت فعلی
          } else {
            _getLocation(); // اگر موقعیت نداریم، دوباره تلاش کن
          }
        },
        tooltip: 'موقعیت من',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}