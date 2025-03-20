import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';


class ProfileService{
  static const String apiUrl = "http://10.0.2.2:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');
  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  Future<Map<String, dynamic>> _postRequest({required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$apiUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    try {
      // Ensure endpoint starts with a slash if not already
      String formattedEndpoint =
      endpoint.startsWith('/') ? endpoint : '/$endpoint';
      debugPrint('Making GET request to: $apiUrl$formattedEndpoint');
      debugPrint('Using token: $token');

      final response = await http.get(
        Uri.parse('$apiUrl$formattedEndpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint("API Request Error: $e");
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        debugPrint("API Error Response: $responseBody");
        return {"error": responseBody["error"] ?? "Unknown error"};
      }
    } catch (e) {
      debugPrint("Error parsing response: $e");
      return {"error": "Failed to parse response: $e"};
    }
  }

  Future<Map<String, dynamic>> _putRequest({required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    try {
      final response = await http.put(
        Uri.parse('$apiUrl$endpoint'),
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

  ///
  /// Update Client/Tasker Information
  ///
  Future<Map<String, dynamic>> updateTasker(TaskerModel tasker) async {
    final userId = await getUserId();

    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    return await _putRequest(endpoint: "/user/updateTasker", body: tasker.toJson());
  }

  Future<Map<String, dynamic>> updateClient(ClientModel client) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }
    return await _putRequest(endpoint: "/user/updateClient", body: client.toJson());
  }
}