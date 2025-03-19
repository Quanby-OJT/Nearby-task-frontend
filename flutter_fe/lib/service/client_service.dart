import 'package:flutter_fe/model/tasker_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:get_storage/get_storage.dart';

class ClientServices {
  static const String apiUrl = "http://localhost:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');
  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$endpoint'),
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
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }

  Future<List<UserModel>> fetchAllTasker() async {
    final userId = await getUserId();
    if (userId == null) return [];

    try {
      final allTaskersResponse = await _getRequest("/client/getAllTaskers");
      final savedTaskResponse =
          await _getRequest("/client/getsavedTask/$userId");

      debugPrint("All Taskers Response: ${allTaskersResponse.length}");

      final allTaskers = allTaskersResponse["taskers"] as List<dynamic>? ?? [];

      final likedTaskerIds =
          (savedTaskResponse["liked_tasks"] as List<dynamic>? ?? [])
              .map<int>((task) => task["tasker_id"] as int)
              .toSet();

      debugPrint("Liked Tasker IDs: ${likedTaskerIds.toString()}");
      final taskerList = allTaskers
          .where((tasker) {
            final taskerId = tasker["user_id"];
            return taskerId is int && !likedTaskerIds.contains(taskerId);
          })
          .map((tasker) => UserModel.fromJson(tasker))
          .toList();

      debugPrint("Unliked Taskers: ${taskerList.toString()}");
      return taskerList;
    } catch (e) {
      debugPrint("Error fetching taskers: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> saveLikedTasker(int taskID) async {
    final userId = await getUserId();

    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }
    return _postRequest(endpoint: "/liketasker", body: {
      "user_id": int.parse(userId),
      "task_post_id": taskID,
      "created_at": DateTime.now().toString()
    });
  }

  Future<Map<String, dynamic>> unlikeTask(int taskId) async {
    try {
      String? userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint("User not logged in, cannot unlike job");
        return {
          'success': false,
          'message': 'Please log in to unlike jobs',
        };
      }

      debugPrint("Client ID: " + userId);
      debugPrint("Client ID: " + taskId.toString());

      final response = await _deleteRequest(
          "/unlikeTask", {"client_id": int.parse(userId), "tasker_id": taskId});

      return {
        'success': true,
        'message':
            response["message"] ?? "An Error Occurred while unliking job",
      };
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {"error": "An Error Occured while getting all jobs."};
    }
  }

  Future<Map<String, dynamic>> _deleteRequest(
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

  Future<List<UserModel>> fetchUserLikedTasks() async {
    final userId = await getUserId();
    if (userId == null) return [];

    try {
      final likedJobsResponse =
          await _getRequest("/client/getsavedTask/$userId");
      final allJobsResponse = await _getRequest("/client/getAllTaskers");

      debugPrint("Liked Jobs Response: ${likedJobsResponse.toString()}");
      debugPrint("All Jobs Response: ${allJobsResponse.toString()}");

      final likedJobIds =
          (likedJobsResponse["liked_tasks"] as List<dynamic>? ?? [])
              .map<int>((job) => job["tasker_id"] as int)
              .toSet();

      final filteredJobs = (allJobsResponse["taskers"] as List<dynamic>? ?? [])
          .where((job) {
            final jobId = job["user_id"];
            return jobId is int && likedJobIds.contains(jobId);
          })
          .map((job) => UserModel.fromJson(job))
          .toList();
      return filteredJobs;
    } catch (e) {
      debugPrint("Error fetching liked jobs: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$apiUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }
}
