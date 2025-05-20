import 'package:flutter/material.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/config/url_strategy.dart';
import 'dart:convert';
import 'package:flutter_fe/model/setting.dart';

class SettingService {
  static String url = apiUrl ?? "http://192.168.43.15:5000";
  static final storage = GetStorage();
  static final http.Client _client = http.Client();
  Future setLocation(
    int userId,
    double latitude,
    double longitude,
    String city,
    String province,
  ) async {
    debugPrint('Setting location: $latitude, $longitude, $city, $province');
    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/set-location/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'province': province
      }),
    );
    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      debugPrint('Location set successfully');
      return "true";
    } else {
      debugPrint('Failed to set location');
      return "false";
    }
  }

  Future<SettingModel> getLocation(int userId) async {
    debugPrint('Getting location for user ID: $userId');
    final token = await AuthService.getSessionToken();
    final response = await _client.get(
      Uri.parse('$url/get-location/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Location retrieved successfully');
      final responseData = json.decode(response.body);

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final data = responseData['data'];

        if (data is List && data.isNotEmpty) {
          return SettingModel.fromJson(data[0]);
        } else if (data is Map<String, dynamic>) {
          return SettingModel.fromJson(data);
        }
      }

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        final String message = responseData['message'] ?? '';
        if (message.contains('[{')) {
          final dataStartIndex = message.indexOf('[{');
          final dataJson = message.substring(dataStartIndex);
          try {
            final parsedData = json.decode(dataJson);
            if (parsedData is List && parsedData.isNotEmpty) {
              return SettingModel.fromJson(parsedData[0]);
            }
          } catch (e) {
            debugPrint('Error parsing data from message: $e');
            return SettingModel();
          }
        }
      }

      debugPrint(
          'No valid location data found, returning default SettingModel');
      return SettingModel();
    } else if (response.statusCode == 404) {
      debugPrint('Location not found for user ID: $userId');
      return SettingModel();
    } else {
      debugPrint('Failed to retrieve location: ${response.statusCode}');
      throw Exception('Failed to retrieve location: ${response.statusCode}');
    }
  }

  Future<void> updateSpecialization(
      int userId, List<String> specialization) async {
    debugPrint('Updating specialization for user ID: $userId');
    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/update-specialization/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'specialization': specialization}),
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Specialization updated successfully');
    } else {
      debugPrint('Failed to update specialization');
      throw Exception(
          'Failed to update specialization: ${response.statusCode}');
    }
  }

  updateDistance(int userId, double distance, RangeValues ageRange,
      bool showFurtherAway) async {
    debugPrint('Updating distance for user ID: $userId');
    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/update-distance/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'Distance': distance,
        'Age_Start': ageRange.start,
        'Age_End': ageRange.end,
        'Show_further_away': showFurtherAway
      }),
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Distance updated successfully');
    } else {
      debugPrint('Failed to update distance');
      throw Exception('Failed to update distance: ${response.statusCode}');
    }
  }

  Future<List<AddressModel>> getAddresses(int userId) async {
    debugPrint('Getting addresses for user ID: $userId');
    final token = await AuthService.getSessionToken();
    final response = await _client.get(
      Uri.parse('$url/get-addresses/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('Response Status Code of addresses: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic> &&
          responseData['data'] != null) {
        final addressData = responseData['data']['address'] as List<dynamic>?;
        if (addressData != null && addressData.isNotEmpty) {
          return addressData
              .map((addressJson) =>
                  AddressModel.fromJson(addressJson as Map<String, dynamic>))
              .toList();
        }
      }
      debugPrint('No addresses found in response');
      return [];
    } else {
      debugPrint('Failed to retrieve addresses: ${response.statusCode}');
      throw Exception('Failed to retrieve addresses: ${response.statusCode}');
    }
  }

  Future setAddress(
    int userId,
    double latitude,
    double longitude,
    String formattedAddress,
    String region,
    String province,
    String city,
    String barangay,
    String street,
    String postalCode,
    String country,
  ) async {
    debugPrint('Setting address: latitude=$latitude, longitude=$longitude, '
        'formattedAddress=$formattedAddress, region=$region, province=$province, '
        'city=$city, barangay=$barangay, street=$street, postalCode=$postalCode, country=$country');

    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/set-address/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'formatted_Address': formattedAddress,
        'region': region,
        'province': province,
        'city': city,
        'barangay': barangay,
        'street': street,
        'postal_code': postalCode,
        'country': country,
      }),
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Address set successfully');
      return "true";
    } else {
      debugPrint('Failed to set address: ${response.body}');
      throw Exception('Failed to set address: ${response.statusCode}');
    }
  }
}
