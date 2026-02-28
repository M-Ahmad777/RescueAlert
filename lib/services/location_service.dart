import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  String _lastAddress = 'Fetching location...';
  StreamSubscription<Position>? _sub;

  Position? get lastPosition => _lastPosition;
  String get lastAddress => _lastAddress;

  Future<bool> requestPermission() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return false;
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final ok = await requestPermission();
    if (!ok) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = pos;
      await _geocode(pos);
      return pos;
    } catch (_) {
      return _lastPosition;
    }
  }

  Future<void> startTracking({
    required void Function(Position) onPosition,
    required void Function(String) onAddress,
  }) async {
    final ok = await requestPermission();
    if (!ok) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) async {
      _lastPosition = pos;
      onPosition(pos);
      final addr = await _geocode(pos);
      onAddress(addr);
    });
  }

  void stopTracking() {
    _sub?.cancel();
    _sub = null;
  }

  Future<String> _geocode(Position pos) async {
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 5));

      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        ];
        _lastAddress = parts.isNotEmpty
            ? parts.join(', ')
            : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }
    } catch (_) {
      _lastAddress = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    }
    return _lastAddress;
  }

  String getMapsUrl() {
    if (_lastPosition == null) return '';
    return 'https://maps.google.com/?q=${_lastPosition!.latitude},${_lastPosition!.longitude}';
  }

  String getCoordinatesString() {
    if (_lastPosition == null) return 'Unknown location';
    return '${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}';
  }
}