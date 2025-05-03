import 'package:flutter/material.dart';
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
    int taskerId,
    double latitude,
    double longitude,
  ) async {
    debugPrint('Setting location: $latitude, $longitude');
    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/set-location/$taskerId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
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

  Future<SettingModel> getLocation(int taskerId) async {
    debugPrint('Getting location for tasker ID: $taskerId');
    final token = await AuthService.getSessionToken();
    final response = await _client.get(
      Uri.parse('$url/get-location/$taskerId'),
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
          }
        }
      }

      debugPrint(
          'No valid location data found, returning default SettingModel');
      return SettingModel();
    } else {
      debugPrint('Failed to retrieve location: ${response.statusCode}');
      throw Exception('Failed to retrieve location: ${response.statusCode}');
    }
  }
}
