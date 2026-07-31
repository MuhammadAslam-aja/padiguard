import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class WeatherData {
  final String cityName;
  final String regionName;
  final double temperature;
  final int humidity;
  final String description;
  final String icon;
  final double lat;
  final double lon;

  WeatherData({
    required this.cityName,
    required this.regionName,
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.lat,
    required this.lon,
  });
}

/// WeatherService menggunakan backend PHP sebagai proxy ke:
/// - Open-Meteo (https://open-meteo.com/) — 100% GRATIS, tanpa API key
/// - Nominatim OpenStreetMap — 100% GRATIS, tanpa API key
///
/// Proxy melalui backend menghindari masalah CORS di Flutter Web browser.
class WeatherService {
  // ─── GPS Location ──────────────────────────────────────────────────────────

  /// Get current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  // ─── Weather Caching ────────────────────────────────────────────────────────
  static WeatherData? _cachedWeather;
  static DateTime? _cacheTime;

  /// Get cached weather if less than 30 minutes old
  static WeatherData? get cachedWeather {
    if (_cachedWeather != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!).inMinutes < 30) {
        return _cachedWeather;
      }
    }
    return null;
  }

  // ─── Weather via Backend Proxy ─────────────────────────────────────────────

  /// Fetch weather via backend PHP proxy (Open-Meteo + Nominatim)
  /// Endpoint: GET /weather/current?lat=...&lon=...
  static Future<WeatherData?> fetchWeatherByCoords(double lat, double lon, {bool forceRefresh = false}) async {
    if (!forceRefresh && cachedWeather != null) {
      return cachedWeather;
    }

    try {
      final base = AppConstants.baseUrl;
      final endpoint = (base.endsWith('/api/') || base.endsWith('/api'))
          ? '${base.endsWith('/') ? base : '$base/'}weather/current?lat=$lat&lon=$lon'
          : '${base.endsWith('/') ? base : '$base/'}api/weather/current?lat=$lat&lon=$lon';
      final url = Uri.parse(endpoint);

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['weather'] != null) {
          final w = data['weather'] as Map<String, dynamic>;
          final weather = WeatherData(
            cityName:    w['city_name']   ?? '',
            regionName:  w['region_name'] ?? 'Lokasi Anda',
            temperature: (w['temperature'] as num).toDouble(),
            humidity:    (w['humidity']    as num).toInt(),
            description:  w['description'] ?? '',
            icon:         w['icon']        ?? '01d',
            lat:          (w['lat']        as num).toDouble(),
            lon:          (w['lon']        as num).toDouble(),
          );
          _cachedWeather = weather;
          _cacheTime = DateTime.now();
          return weather;
        }
      } else {
        debugPrint('Weather proxy error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    }
    return cachedWeather;
  }

  // ─── Icon & Recommendation ─────────────────────────────────────────────────

  /// Map icon code (OWM-style format) to Flutter icon
  static IconData getWeatherIcon(String icon) {
    final id = icon.length >= 2 ? icon.substring(0, 2) : '01';
    switch (id) {
      case '01': return Icons.wb_sunny;
      case '02': return Icons.wb_cloudy;
      case '03':
      case '04': return Icons.cloud;
      case '09':
      case '10': return Icons.grain;
      case '11': return Icons.thunderstorm;
      case '13': return Icons.ac_unit;
      case '50': return Icons.foggy;
      default:   return Icons.wb_cloudy_outlined;
    }
  }

  /// Generate farming recommendation based on weather
  static String getFarmingRecommendation(WeatherData weather) {
    final temp     = weather.temperature;
    final humidity = weather.humidity;
    final desc     = weather.description.toLowerCase();

    if (desc.contains('hujan') || desc.contains('gerimis')) {
      return 'Cuaca hujan, hindari penyemprotan pestisida. Pantau drainase sawah Anda.';
    } else if (desc.contains('badai') || desc.contains('petir')) {
      return 'Cuaca ekstrem. Tunda aktivitas lapangan dan amankan peralatan.';
    } else if (desc.contains('kabut')) {
      return 'Berkabut, waspadai kelembapan tinggi. Periksa tanaman dari serangan jamur.';
    } else if (temp > 33) {
      return 'Suhu tinggi, pastikan irigasi cukup. Pantau tanaman untuk mencegah layu.';
    } else if (temp < 22) {
      return 'Suhu rendah, waspadai serangan jamur. Kurangi kelembapan sawah.';
    } else if (humidity > 85) {
      return 'Kelembapan tinggi, waspadai perkembangan hama wereng dan jamur.';
    } else if (temp >= 26 && temp <= 32 && humidity >= 60 && humidity <= 80) {
      return 'Suhu ideal untuk pertumbuhan padi. Rekomendasi: Lakukan pemupukan hari ini.';
    } else {
      return 'Kondisi cuaca cukup baik. Lanjutkan aktivitas pertanian seperti biasa.';
    }
  }
}
