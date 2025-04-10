import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/auth_service.dart';

import '../model/conversation.dart';

class TaskDetailsService {
  static final String apiUrl = "http://localhost:5000/connect";
  final storage = GetStorage();

  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body);
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }

  static Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    try {
      final response = await http.get(
        Uri.parse('$apiUrl$endpoint'),
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

  static Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    final response = await http.post(Uri.parse("$apiUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _deleteRequest(
      String endpoint, Map<String, dynamic> body) async {
    final token = await AuthService.getSessionToken();
    try {
      final request = http.Request("DELETE", Uri.parse('$apiUrl$endpoint'))
        ..headers["Authorization"] = "Bearer $token"
        ..headers["Content-Type"] = "application/json"
        ..body = jsonEncode(body);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {"error": "Request failed: $e"};
    }
  }

  static Future<TaskModel?> fetchTaskDetails(int taskId) async {
    try {
      // final url = Uri.parse("$apiUrl/displayLikedJob/$taskId");
      //
      // final response = await http.get(url);
      //
      // if (response.statusCode == 200) {
      //   final Map<String, dynamic> jsonData = jsonDecode(response.body);
      //
      //   if (jsonData.containsKey('tasks') && jsonData['tasks'].isNotEmpty) {
      //     return TaskModel.fromJson(jsonData['tasks'][0]);
      //   }
      // }

      final data = await _getRequest("$apiUrl/displayLikedJob/$taskId");

      return TaskModel.fromJson(data['tasks'][0]);
    } catch (e) {
      debugPrint("Exception in fetchTaskDetails: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getAllTakenTasks() async {
    try {
      final userId = await storage.read('user_id');
      final data = await _getRequest("/all-messages/$userId");

      return data;
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {"error": "An Error Occured while getting all jobs."};
    }
  }

  //This is for client.
  Future<Map<String, dynamic>> updateTaskStatus(
      int taskTakenId, String? newStatus) async {
    try {
      return await _postRequest(endpoint: "/update-status-client", body: {
        "task_id": taskTakenId,
        "status": newStatus,
      });
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "An Error Occured while updating task status."};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
      Conversation conversation) async {
    try {
      return await _postRequest(
          endpoint: "/send-message", body: conversation.toJson());
      // String token = await AuthService.getSessionToken();
      //
      // final response = await http.post(Uri.parse("$apiUrl/send-message"),
      //     headers: {
      //       "Authorization": "Bearer $token",
      //       "Content-Type": "application/json"
      //     },
      //     body: jsonEncode(conversation.toJson()));
      //
      // var data = jsonDecode(response.body);
      //
      // if (response.statusCode == 200) {
      //   return {"message": data["message"] ?? "Successfully Sent the Message"};
      // } else if (response.statusCode == 400) {
      //   return {
      //     "error": data["errors"] ?? "Please Check Your inputs and try again"
      //   };
      // } else {
      //   // Handle unexpected response statuses
      //   return {
      //     "error":
      //     "Unexpected error occurred. Status code: ${response.statusCode}"
      //   };
      // }
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {
        "error": "An Error Occured while Sending a Message. Please Try Again"
      };
    }
  }

  static Future<Map<String, dynamic>> getMessages(int taskTakenId) async {
    try {
      final data = await _getRequest("/messages/$taskTakenId");

      debugPrint("All Messages Data: ${data.toString()}");

      return data;
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {
        "error":
            "An error occurred while retrieving your conversation. Please try again."
      };
    }
  }
}
