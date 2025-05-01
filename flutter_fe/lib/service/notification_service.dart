import 'package:flutter/foundation.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../config/url_strategy.dart';

class NotificationService {
  static final String url = apiUrl ?? "http://localhost:5000/connect";

  final storage = GetStorage();

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body);
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }

  Future<Map<String, dynamic>> getPendingRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-pending/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting pending requests"};
    }
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
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
      debugPrint("Message Retrieval Error: $e");
      debugPrint(stackTrace.toString());
      return {
        "error": "An Error while retrieving your messages. Please Try Again."
      };
    }
  }

  Future<Map<String, dynamic>> getNotificationRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-request/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting notifications"};
    }
  }

  Future<Map<String, dynamic>> getRejectedRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-reject/$userId");
      debugPrint("Rejected Requests: $data");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting rejected requests"};
    }
  }

  Future<Map<String, dynamic>> getOngoingRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-ongoing/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting ongoing requests"};
    }
  }

  Future<Map<String, dynamic>> getReviewRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-review/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting review requests"};
    }
  }

  Future<Map<String, dynamic>> getFinishRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-finish/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting finish requests"};
    }
  }

  Future<Map<String, dynamic>> getConfirmedRequests(int userId) async {
    try {
      final data = await _getRequest("/notifications-tasker-confirmed/$userId");
      return data;
    } catch (e, st) {
      debugPrint("Service error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting confirmed requests"};
    }
  }
}
