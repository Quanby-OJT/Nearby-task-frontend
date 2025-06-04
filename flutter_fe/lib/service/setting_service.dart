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

  Future<Map<String, dynamic>> _deleteRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    debugPrint("Deleting address on URL: $url$endpoint");
    final response = await http.delete(
      Uri.parse("$url$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _putRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    debugPrint(body.toString());
    try {
      final response = await http.put(
        Uri.parse('$url$endpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed. Please Try Again."};
    }
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    debugPrint("Current Session: ${await storage.read('session')}");
    final token = await AuthService.getSessionToken();
    try {
      final response = await http.get(
        Uri.parse('$url$endpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      print("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body.toString());
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      // Ensure the response includes a success flag
      Map<String, dynamic> result = {...responseBody};
      // If the response doesn't have a 'success' key, add it
      if (!result.containsKey('success')) {
        result['success'] = true;
      }
      return result;
    } else {
      // Return error with success flag set to false
      return {
        "success": false,
        "error": responseBody["error"] ?? "Unknown error",
        "message": responseBody["message"] ?? "Failed to process request"
      };
    }
  }

  Future setLocation(
    int userId,
    double latitude,
    double longitude,
    String city,
    String province,
  ) async {
    debugPrint('Setting location: $latitude, $longitude, $city, $province');
    final token = await AuthService.getSessionToken();
    final response = await _putRequest(
        endpoint: '/set-location/$userId',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'city': city,
          'province': province
        });
    if (response.containsKey('message')) {
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
    final response = await _getRequest('/get-location/$userId');

    if (response.containsKey('message')) {
      debugPrint('Location retrieved successfully');

      if (response.containsKey('data')) {
        final data = response['data'];

        if (data is List && data.isNotEmpty) {
          return SettingModel.fromJson(data[0]);
        } else if (data is Map<String, dynamic>) {
          return SettingModel.fromJson(data);
        }
      }

      if (response.containsKey('message')) {
        final String message = response['message'] ?? '';
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
    } else if (response.containsKey('error')) {
      debugPrint('Location not found for user ID: $userId');
      return SettingModel();
    } else {
      debugPrint('Failed to retrieve location: ${response['error']}');
      return SettingModel();
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
    // debugPrint('Getting addresses for user ID: $userId');
    // final token = await AuthService.getSessionToken();
    // final response = await _client.get(
    //   Uri.parse('$url/get-addresses/$userId'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $token',
    //   },
    // );
    //
    // debugPrint('Response Status Code of addresses: ${response.statusCode}');
    // debugPrint('Response Body: ${response.body}');
    //
    // if (response.statusCode == 200) {
    //   final responseData = json.decode(response.body);
    //   if (responseData is Map<String, dynamic> &&
    //       responseData['data'] != null) {
    //     final addressData = responseData['data']['address'] as List<dynamic>?;
    //     if (addressData != null && addressData.isNotEmpty) {
    //       return addressData
    //           .map((addressJson) =>
    //               AddressModel.fromJson(addressJson as Map<String, dynamic>))
    //           .toList();
    //     }
    //   }
    //   debugPrint('No addresses found in response');
    //   return [];
    // } else {
    //   debugPrint('Failed to retrieve addresses: ${response.statusCode}');
    //   throw Exception('Failed to retrieve addresses: ${response.statusCode}');
    // }

    final response = await _getRequest('/get-addresses/$userId');

    if (response.containsKey('data') && response['data'] != null) {
      final addressData = response['data']['address'] as List<dynamic>?;
      if (addressData != null && addressData.isNotEmpty) {
        return addressData
            .map((addressJson) =>
                AddressModel.fromJson(addressJson as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('No addresses found in response');
        return [];
      }
    } else {
      debugPrint('No addresses found in response');
      return [];
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
    String remarks,
  ) async {
    debugPrint('Setting address: latitude=$latitude, longitude=$longitude, '
        'formattedAddress=$formattedAddress, region=$region, province=$province, '
        'city=$city, barangay=$barangay, street=$street, postalCode=$postalCode, country=$country');

    //This is a far more efficient code where it will only call putRequest at once.
    final response = await _putRequest(endpoint: '/set-address/$userId', body: {
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
      'remarks': remarks,
    });

    if (response.containsKey('message')) {
      debugPrint('Address set successfully');
      return "true";
    } else {
      debugPrint('Failed to set address');
      return "false";
    }
  }

  Future<bool> setDefaultAddress(int userId, String addressId) async {
    final response =
        await _putRequest(endpoint: '/set-default-address/$userId', body: {
      'address_id': addressId,
    });

    if (response.containsKey('message')) {
      debugPrint('Default address set successfully');
      return true;
    } else {
      debugPrint('Failed to set default address');
      return false;
    }
  }

  Future updateAddress(
    String addressId,
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
    String remarks,
  ) async {
    debugPrint('Setting address: latitude=$latitude, longitude=$longitude, '
        'formattedAddress=$formattedAddress, region=$region, province=$province, '
        'city=$city, barangay=$barangay, street=$street, postalCode=$postalCode, country=$country');

    final token = await AuthService.getSessionToken();
    final response = await _client.put(
      Uri.parse('$url/update-address/$addressId'),
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
        'remarks': remarks,
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

  Future<bool> deleteAddress(String addressId) async {
    try {
      debugPrint('Deleting address with ID: $addressId');
      final token = await AuthService.getSessionToken();
      final response = await _client.delete(
        Uri.parse('$url/delete-address/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.body.contains('status')) {
        debugPrint('Address deleted successfully');
        final responseData = json.decode(response.body);
        return responseData['status'];
      } else {
        debugPrint('Failed to delete address: ${response.body}');
        throw Exception('Failed to delete address: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      throw Exception('Failed to delete address: $e');
    }
  }
}
