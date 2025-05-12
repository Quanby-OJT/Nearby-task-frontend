import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhilippineLocationService {
  // Base URL for the Philippines Geo API
  // Note: This is a placeholder URL for a public API. Replace with actual API endpoint
  static const String baseUrl = 'https://psgc.gitlab.io/api';

  // Singleton instance
  static final PhilippineLocationService _instance =
      PhilippineLocationService._internal();

  // Cache data to reduce API calls
  final Map<String, dynamic> _cache = {};

  // Factory constructor
  factory PhilippineLocationService() {
    return _instance;
  }

  // Private constructor
  PhilippineLocationService._internal();

  // Get all regions
  Future<List<Map<String, dynamic>>> getRegions() async {
    try {
      // Check cache first
      if (_cache.containsKey('regions')) {
        return List<Map<String, dynamic>>.from(_cache['regions']);
      }

      // Make API request
      final response = await http.get(Uri.parse('$baseUrl/regions'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> regions = data
            .map((item) => {
                  'code': item['code'],
                  'name': item['name'],
                  'regionName': item['regionName'] ?? item['name'],
                })
            .toList();

        // Sort regions by name
        regions.sort((a, b) => a['name'].compareTo(b['name']));

        // Cache the result
        _cache['regions'] = regions;

        return regions;
      } else {
        debugPrint('Failed to load regions: ${response.statusCode}');
        return _getFallbackRegions();
      }
    } catch (e) {
      debugPrint('Error fetching regions: $e');
      return _getFallbackRegions();
    }
  }

  // Get provinces by region code
  Future<List<Map<String, dynamic>>> getProvincesByRegion(
      String regionCode) async {
    try {
      // Check cache first
      final String cacheKey = 'provinces_$regionCode';
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }

      // Make API request
      final response =
          await http.get(Uri.parse('$baseUrl/regions/$regionCode/provinces'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> provinces = data
            .map((item) => {
                  'code': item['code'],
                  'name': item['name'],
                })
            .toList();

        // Sort provinces by name
        provinces.sort((a, b) => a['name'].compareTo(b['name']));

        // Cache the result
        _cache[cacheKey] = provinces;

        return provinces;
      } else {
        debugPrint('Failed to load provinces: ${response.statusCode}');
        return _getFallbackProvinces(regionCode);
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
      return _getFallbackProvinces(regionCode);
    }
  }

  // Get cities by province code
  Future<List<Map<String, dynamic>>> getCitiesByProvince(
      String provinceCode) async {
    try {
      // Check cache first
      final String cacheKey = 'cities_$provinceCode';
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }

      // Make API request
      final response = await http.get(
          Uri.parse('$baseUrl/provinces/$provinceCode/cities-municipalities'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> cities = data
            .map((item) => {
                  'code': item['code'],
                  'name': item['name'],
                  'cityClass': item['cityClass'] ?? '',
                })
            .toList();

        // Sort cities by name
        cities.sort((a, b) => a['name'].compareTo(b['name']));

        // Cache the result
        _cache[cacheKey] = cities;

        return cities;
      } else {
        debugPrint('Failed to load cities: ${response.statusCode}');
        return _getFallbackCities(provinceCode);
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      return _getFallbackCities(provinceCode);
    }
  }

  // Get barangays by city code
  Future<List<Map<String, dynamic>>> getBarangaysByCity(String cityCode) async {
    try {
      // Check cache first
      final String cacheKey = 'barangays_$cityCode';
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }

      // Make API request
      final response = await http
          .get(Uri.parse('$baseUrl/cities-municipalities/$cityCode/barangays'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> barangays = data
            .map((item) => {
                  'code': item['code'],
                  'name': item['name'],
                })
            .toList();

        // Sort barangays by name
        barangays.sort((a, b) => a['name'].compareTo(b['name']));

        // Cache the result
        _cache[cacheKey] = barangays;

        return barangays;
      } else {
        debugPrint('Failed to load barangays: ${response.statusCode}');
        return _getFallbackBarangays(cityCode);
      }
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
      return _getFallbackBarangays(cityCode);
    }
  }

  // Helper method to get formatted region display name
  String getRegionDisplayName(Map<String, dynamic> region) {
    if (region.containsKey('regionName') && region['regionName'] != null) {
      return '${region['name']} (${region['regionName']})';
    }
    return region['name'];
  }

  // Fallback data in case API fails
  List<Map<String, dynamic>> _getFallbackRegions() {
    return [
      {'code': 'NCR', 'name': 'National Capital Region', 'regionName': 'NCR'},
      {
        'code': 'CAR',
        'name': 'Cordillera Administrative Region',
        'regionName': 'CAR'
      },
      {'code': '01', 'name': 'Ilocos Region', 'regionName': 'Region I'},
      {'code': '02', 'name': 'Cagayan Valley', 'regionName': 'Region II'},
      {'code': '03', 'name': 'Central Luzon', 'regionName': 'Region III'},
      {'code': '4A', 'name': 'CALABARZON', 'regionName': 'Region IV-A'},
      {'code': '4B', 'name': 'MIMAROPA', 'regionName': 'Region IV-B'},
      {'code': '05', 'name': 'Bicol Region', 'regionName': 'Region V'},
      {'code': '06', 'name': 'Western Visayas', 'regionName': 'Region VI'},
      {'code': '07', 'name': 'Central Visayas', 'regionName': 'Region VII'},
      {'code': '08', 'name': 'Eastern Visayas', 'regionName': 'Region VIII'},
      {'code': '09', 'name': 'Zamboanga Peninsula', 'regionName': 'Region IX'},
      {'code': '10', 'name': 'Northern Mindanao', 'regionName': 'Region X'},
      {'code': '11', 'name': 'Davao Region', 'regionName': 'Region XI'},
      {'code': '12', 'name': 'SOCCSKSARGEN', 'regionName': 'Region XII'},
      {'code': '13', 'name': 'Caraga', 'regionName': 'Region XIII'},
      {
        'code': 'BARMM',
        'name': 'Bangsamoro Autonomous Region in Muslim Mindanao',
        'regionName': 'BARMM'
      },
    ];
  }

  List<Map<String, dynamic>> _getFallbackProvinces(String regionCode) {
    if (regionCode == 'NCR') {
      return [
        {'code': 'NCR', 'name': 'Metro Manila'}
      ];
    } else if (regionCode == '4A') {
      return [
        {'code': 'CAV', 'name': 'Cavite'},
        {'code': 'LAG', 'name': 'Laguna'},
        {'code': 'BAT', 'name': 'Batangas'},
        {'code': 'RIZ', 'name': 'Rizal'},
        {'code': 'QUE', 'name': 'Quezon'},
      ];
    }
    return [];
  }

  List<Map<String, dynamic>> _getFallbackCities(String provinceCode) {
    if (provinceCode == 'NCR') {
      return [
        {'code': 'MNL', 'name': 'Manila'},
        {'code': 'QZN', 'name': 'Quezon City'},
        {'code': 'CAL', 'name': 'Caloocan'},
        {'code': 'MKT', 'name': 'Makati'},
        {'code': 'PSG', 'name': 'Pasig'},
      ];
    }
    return [];
  }

  List<Map<String, dynamic>> _getFallbackBarangays(String cityCode) {
    // Just return some sample barangays
    return [
      {'code': 'BRG1', 'name': 'Barangay 1'},
      {'code': 'BRG2', 'name': 'Barangay 2'},
      {'code': 'BRG3', 'name': 'Barangay 3'},
    ];
  }
}
