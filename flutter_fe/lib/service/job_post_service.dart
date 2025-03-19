import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:get_storage/get_storage.dart';

class JobPostService {
  static const String apiUrl = "http://10.0.2.2:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body.toString());
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    debugPrint("Current Session: ${await storage.read('session')}");
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
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _postRequest({required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$apiUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _deleteRequest(String endpoint, Map<String, dynamic> body) async {
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

  Future<Map<String, dynamic>> postJob(TaskModel task, int userId) async {
    try {
      Map<String, dynamic> response = await _postRequest(
        endpoint: "/addTask",
        body: {...task.toJson(), "user_id": userId},
      );

      // Ensure the success field is always a boolean
      return {
        'success': response.containsKey('success')
            ? response['success'] == true
            : false,
        'message': response['message'] ?? 'Task posted successfully',
        'error': response['error']
      };
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {'success': false, "error": "Error: $e"};
    }
  }

  Future<List<SpecializationModel>> getSpecializations() async {
    final response = await _getRequest("/get-specializations");
    if (response["specializations"] != null) {
      return (response["specializations"] as List)
          .map((item) => SpecializationModel.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<TaskModel?> fetchTaskInformation(int taskID) async {
    try {
      Map<String, dynamic> response = await _getRequest("/displayTask/$taskID");
      debugPrint("Message Data Retrieved: ${response.toString()}");

      // Check if response contains the "tasks" key and it's a Map
      if (response.containsKey("tasks") && response["tasks"] is Map) {
        Map<String, dynamic> taskData =
            response["tasks"] as Map<String, dynamic>;
        debugPrint("Mapped: ${taskData.toString()}");
        return TaskModel.fromJson(taskData);
      }

      // Return null if no tasks found or invalid format
      debugPrint("No valid task data found in response");
      return null;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      debugPrintStack();
      return null;
    }
  }

  Future<List<TaskModel>> fetchAllJobs() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint("User ID is null, returning empty list");
        return [];
      }

      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
      final allJobsResponse = await _getRequest("/displayTask");

      // Log responses for debugging
      debugPrint("Liked Jobs Response: $likedJobsResponse");
      debugPrint("All Jobs Response: $allJobsResponse");

      // Check if allJobsResponse is a valid Map with tasks
      if (allJobsResponse.containsKey("error")) {
        debugPrint(
            "Error fetching jobs: ${allJobsResponse['error'] ?? 'Invalid response'}");
        return [];
      }

      // Ensure 'tasks' exists and is a List
      final tasks = allJobsResponse["tasks"];
      if (tasks == null || tasks is! List) {
        debugPrint(
            "Unexpected response format: 'tasks' is missing or not a list");
        return [];
      }

      return tasks
          .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint("Exception in fetchAllJobs: $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<Map<String, dynamic>> saveLikedJob(int jobId) async {
    // debugPrint(jobId.toString());
    final userId = await getUserId();
    // debugPrint(userId);
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }
    return _postRequest(endpoint: "/likeJob", body: {
      "user_id": int.parse(userId),
      "task_id": jobId,
      "created_at": DateTime.now().toString()
    });
  }

  Future<Map<String, dynamic>> unlikeJob(int jobId) async {
    try {
      String? userId = await getUserId();
      if (userId == null) {
        debugPrint("User not logged in, cannot unlike job");
        return {
          'success': false,
          'message': 'Please log in to unlike jobs',
        };
      }

      return _deleteRequest(
          "/unlikeJob", {"user_id": int.parse(userId), "job_post_id": jobId});
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {"error": "An Error Occured while getting all jobs."};
    }
  }

  Future<Map<String, dynamic>> fetchJobsForClient(int clientId) async {
    return _getRequest("/display-task-for-client/$clientId");
  }

  //Not sure if this will work. Needs more debugging.
  Future<List<TaskModel>> fetchUserLikedJobs() async {
    try {
      String? userId = await getUserId();

      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
      final allJobsResponse = await _getRequest("/displayTask");
      debugPrint(likedJobsResponse.toString());

      final allJobsList = (allJobsResponse["tasks"] as List<dynamic>?)?.map((job) => TaskModel.fromJson(job)).toList() ?? [];

       if (likedJobsResponse.containsKey("liked_tasks")) {
          final likedJobs = likedJobsResponse["liked_tasks"] as List<dynamic>;
            debugPrint("Raw liked jobs: $likedJobs");
          final Set<int> likedJobIds = likedJobs.where((job) => job["job_post_id"] != null)
            .map<int>((job) => (job["job_post_id"] is int ? job["job_post_id"] : int.parse(job["job_post_id"].toString())) as int)
            .toSet();

            debugPrint("Liked Jobs Response ${likedJobsResponse.toString()}");
            debugPrint("All Jobs: ${likedJobIds.toString()}");

            final filteredJobs = allJobsList.where((job) => likedJobIds.contains(job.id)).toList();

            debugPrint("Filtered Jobs: ${filteredJobs.toString()}");
            return filteredJobs;
       }
       else{
        return [];
       }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  Future<Map<String, dynamic>> assignTask(
      int? taskId, int? clientId, int? taskerId) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    debugPrint(taskId.toString() +
        " " +
        clientId.toString() +
        " " +
        taskerId.toString());

    return _postRequest(endpoint: "$apiUrl/assign-task", body: {
      "tasker_id": taskerId,
      "client_id": clientId,
      "task_id": taskId
    });
  }
}
