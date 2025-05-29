import 'dart:convert';
import 'package:absen_cmi/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banner.dart';
import 'package:logging/logging.dart';

class BannerService {
  static final _logger = Logger('BannerService');
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _cacheKey = 'cached_banners';
  static const String _cacheTimestampKey = 'banners_cache_timestamp';

  Future<List<Banner>> getBanners() async {
    try {
      _logger.info('Fetching banners from API...');
      final response = await http.get(Uri.parse('$_baseUrl/banners'));
      _logger.info('Banner API Response Status: ${response.statusCode}');
      _logger.info('Banner API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        _logger.info('Parsed banner data: $data');

        final banners = _parseBanners(data);
        _logger.info('Successfully parsed ${banners.length} banners');

        // Save to cache only if we have valid banners
        if (banners.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, json.encode(data));
          await prefs.setInt(
              _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
          _logger.info('Saved ${banners.length} banners to cache');
        }

        return banners;
      } else {
        _logger.severe('Failed to load banners: ${response.statusCode}');
        throw Exception('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching banners: $e');
      return [];
    }
  }

  List<Banner> _parseBanners(List<dynamic> data) {
    final List<Banner> validBanners = [];

    for (final item in data) {
      try {
        if (item is Map<String, dynamic>) {
          _logger.info('Parsing banner item: $item');
          final banner = Banner.fromJson(item);
          validBanners.add(banner);
          _logger.info('Successfully parsed banner with id: ${banner.id}');
        } else {
          _logger.warning('Invalid banner item format: $item');
        }
      } catch (e) {
        _logger.severe('Error parsing banner: $e');
        // Skip invalid banners
        continue;
      }
    }

    _logger.info('Total valid banners parsed: ${validBanners.length}');
    return validBanners;
  }

  // Method to force refresh cache
  Future<void> refreshBanners() async {
    _logger.info('Refreshing banner cache...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    _logger.info('Banner cache cleared');
  }
}
