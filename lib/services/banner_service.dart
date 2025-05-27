import 'dart:convert';
import 'package:absen_cmi/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banner.dart';

class BannerService {
  static const String _baseUrl = ApiConfig.cikuraiBaseUrl;
  static const String _cacheKey = 'cached_banners';
  static const String _cacheTimestampKey = 'banners_cache_timestamp';

  Future<List<Banner>> getBanners() async {
    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      // If cache exists and is less than 24 hours old, use it
      if (cachedData != null && cacheTimestamp != null) {
        final cacheAge = now - cacheTimestamp;
        if (cacheAge < 24 * 60 * 60 * 1000) {
          // 24 hours in milliseconds
          final List<dynamic> cachedBanners = json.decode(cachedData);
          return cachedBanners.map((json) => Banner.fromJson(json)).toList();
        }
      }

      // If no cache or cache is old, fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/banners'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final banners = data.map((json) => Banner.fromJson(json)).toList();

        // Save to cache
        await prefs.setString(_cacheKey, json.encode(data));
        await prefs.setInt(_cacheTimestampKey, now);

        return banners;
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      print('Error fetching banners: $e');
      // If API fails, try to use cache even if it's old
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final List<dynamic> cachedBanners = json.decode(cachedData);
        return cachedBanners.map((json) => Banner.fromJson(json)).toList();
      }
      return [];
    }
  }

  // Method to force refresh cache
  Future<void> refreshBanners() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
