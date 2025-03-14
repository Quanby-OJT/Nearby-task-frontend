import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
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

  Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    try {
      String? userId = await getUserId();
      if (userId.isEmpty) {
        debugPrint("Cannot fetch liked jobs: User not logged in");
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("http://localhost:5000/connect/displayLikedJob/$userId");

      debugPrint("Fetching liked jobs from: $url");

      final response = await http.get(url);
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        debugPrint("Decoded JSON data: $jsonData");

        if (jsonData.containsKey('tasks')) {
          final List<dynamic> likedJobs = jsonData['tasks'];
          debugPrint("Raw liked jobs: $likedJobs"); // Debug print

          // Fetch full job details for each liked job
          final jobDetailsResponse = await http
              .get(Uri.parse('http://localhost:5000/connect/displayTask'));

          if (jobDetailsResponse.statusCode == 200) {
            final Map<String, dynamic> allJobsData =
                jsonDecode(jobDetailsResponse.body);
            final List<dynamic> allJobs = allJobsData['tasks'];

            // Get liked job IDs
            final Set<int> likedJobIds =
                likedJobs.map<int>((job) => job['job_post_id'] as int).toSet();

            // Filter and map jobs
            List<TaskModel> taskModels = allJobs
                .where((job) => likedJobIds.contains(job['job_post_id']))
                .map((job) => TaskModel.fromJson(job))
                .toList();

            debugPrint("Successfully parsed ${taskModels.length} tasks");
            return {"tasks": taskModels};
          } else {
            return {"error": "Failed to fetch job details"};
          }
        } else {
          return {"error": "No liked jobs found"};
        }
      } else {
        return {"error": "Failed to fetch liked jobs"};
      }
    } catch (e) {
      return {"error": "Request failed: $e"};
    }
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
    try{
      Future<Map<String, dynamic>> response = _postRequest(
        endpoint: "/addTask",
        body: {...task.toJson(), "user_id": userId},
      );

      return response;
    }catch(e){
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

      // Since response is already a task object, just parse it directly
      return TaskModel.fromJson(response);
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
        debugPrint("Error fetching jobs: ${allJobsResponse['error'] ?? 'Invalid response'}");
        return [];
      }

      // Ensure 'tasks' exists and is a List
      final tasks = allJobsResponse["tasks"];
      if (tasks == null || tasks is! List) {
        debugPrint("Unexpected response format: 'tasks' is missing or not a list");
        return [];
      }

      return tasks
          .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Exception in fetchAllJobs: $e");
      debugPrintStack();
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
    return _postRequest(
      endpoint: "/likeJob",
      body: {
        "user_id": int.parse(userId),
        "task_id": jobId,
        "created_at": DateTime.now().toString()
      }
    );
  }

  Future<Map<String, dynamic>> unlikeJob(int jobId) async {
    try {
      String? userId = await getUserId();
      if (userId.isEmpty) {
        debugPrint("User not logged in, cannot unlike job");
        return {
          'success': false,
          'message': 'Please log in to unlike jobs',
        };
      }

      final response = await _deleteRequest(
          "/unlikeJob", {"user_id": int.parse(userId), "job_post_id": jobId});

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

  Future<Map<String, dynamic>> fetchJobsForClient(int clientId) async {
    return _getRequest("/display-task-for-client/$clientId");
  }

  Future<List<TaskModel>> fetchUserLikedJobs() async {
    try {
      String? userId = await getUserId();
      if (userId.isEmpty) {
        debugPrint("Cannot fetch liked jobs: User not logged in");
        return [];
      }
      final url =
          Uri.parse("http://localhost:5000/connect/displayLikedJob/$userId");
      debugPrint("Fetching liked jobs from: $url");

      final response = await http.get(url);
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        debugPrint("Decoded JSON data: $jsonData");

        if (jsonData.containsKey('tasks')) {
          final List<dynamic> likedJobs = jsonData['tasks'];
          debugPrint("Raw liked jobs: $likedJobs"); // Debug print

          final jobDetailsResponse = await http
              .get(Uri.parse('http://localhost:5000/connect/displayTask'));

    // Explicitly type the list and cast job IDs to int
    final likedJobIds = (likedJobsResponse["tasks"] as List<dynamic>? ?? [])
        .map<int>((job) => (job["task_id"] as int))
        .toSet();

            // Get liked job IDs
            final Set<int> likedJobIds =
                likedJobs.map<int>((job) => job['job_post_id'] as int).toSet();

    final filteredJobs = (allJobsResponse["tasks"] as List<dynamic>? ?? [])
        .where((job) {
      final jobId = job["task_id"]; // Changed from "task_id" to "task_id"
      return jobId is int && likedJobIds.contains(jobId);
    })
        .map((job) => TaskModel.fromJson(job))
        .toList();

    debugPrint("Filtered Jobs: ${filteredJobs.toString()}");
    return filteredJobs;
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

    debugPrint(taskId.toString() + " " + clientId.toString() + " " + taskerId.toString());

    return _postRequest(
        endpoint: "$apiUrl/assign-task",
        body: {
          "tasker_id": taskerId,
          "client_id": clientId,
          "task_id": taskId
        }
    );
  }
}
      