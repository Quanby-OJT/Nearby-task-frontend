import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/auth_service.dart';

import '../config/url_strategy.dart';
import '../model/conversation.dart';

class TaskDetailsService {
  static final String url = apiUrl ?? "http://192.168.1.12:5000/connect";
  static final storage = GetStorage();

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
    debugPrint("API URL: $url");
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

  static Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    final response = await http.post(Uri.parse("$url$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _deleteRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    final response = await http.delete(
      Uri.parse("$url$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );
    return _handleResponse(response);
  }

  static Future<TaskModel?> fetchTaskDetails(int taskId) async {
    try {
      final data = await _getRequest("$url/displayLikedJob/$taskId");
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
      debugPrint("All Messages Data: ${data.toString()}");
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

  //Client/Tasker Conversation
  Future<Map<String, dynamic>> sendMessage(Conversation conversation) async {
    try {
      debugPrint("Current User Role: ${storage.read('role')}");
      return await _postRequest(
          endpoint: "/send-message",
          body: {...conversation.toJson(), 'role': storage.read('role')});
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {
        "error": "An Error Occured while Sending a Message. Please Try Again"
      };
    }
  }

  static Future<void> readMessage(int taskTakenId) async {
    try {
      await _postRequest(endpoint: "/mark-messages-read", body: {
        "task_taken_id": taskTakenId,
        'user_id': storage.read('user_id'),
        "role": storage.read('role')
      });
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
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

  static Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    try {
      return await _deleteRequest("/delete-message/$messageId");
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {
        "error":
            "An error occurred while deleting your message. Please try again."
      };
    }
  }
}
