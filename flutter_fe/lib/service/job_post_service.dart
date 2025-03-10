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

  Future<Map<String, dynamic>> postJob(TaskModel task, int userId) async {
    try {
      Future<Map<String, dynamic>> response = _postRequest(
        endpoint: "/addTask",
        body: {...task.toJson(), "user_id": userId},
      );

      return {'success': true, 'message': response.toString()};
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
      if (taskID <= 0) {
        debugPrint('fetchTaskInformation: No task ID provided');
        return null;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/connect/displayTask/$taskID'),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return TaskModel.fromJson(jsonData);
      }

      debugPrint('Error fetching task $taskID');
      return null;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return null;
    }
  }

  Future<List<TaskModel>> fetchAllJobs() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint("User not authenticated, cannot fetch jobs");
        return [];
      }

      // Fetch all jobs
      final response = await http
          .get(Uri.parse('http://localhost:5000/connect/displayTask'));
      // Fetch liked jobs
      final likedJobsResponse = await http.get(
          Uri.parse('http://localhost:5000/connect/displayLikedJob/${userId}'));

      if (response.statusCode == 200 && likedJobsResponse.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic> likedJobsData =
            jsonDecode(likedJobsResponse.body);

    final tasksResponse = await _getRequest("/displayTask");
    print("Tasks API Response: $tasksResponse"); // Debugging

    if (!tasksResponse.containsKey("tasks")) {
      throw Exception("Unexpected API response format: $tasksResponse");
    }
    return [];
  }

  Future<Map<String, dynamic>> saveLikedJob(int jobId) async {
    try {
      final url = Uri.parse('http://localhost:5000/connect/likeJob');

    final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");

    final likedJobIds = (likedJobsResponse["liked_tasks"] ?? [])
        .map<int>((job) => job["job_post_id"] as int)
        .toSet();

    final tasks = tasksResponse["tasks"];

    if (tasks is! List) {
      throw Exception("tasks is not a List: $tasks");
    }

    // ✅ Convert tasks properly
    List<TaskModel> taskList =
        tasks.map<TaskModel>((task) => TaskModel.fromJson(task)).toList();

    return taskList; // Explicitly returning List<TaskModel>
  }

  Future<Map<String, dynamic>> saveLikedJob(int jobId) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }
    return _postRequest(
        endpoint: "/likeJob",
        body: {"user_id": int.parse(userId), "job_post_id": jobId});
  }

  Future<Map<String, dynamic>> unlikeJob(int jobId) async {
    try {
      String? userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint("User not logged in, cannot unlike job");
        return {
          'success': false,
          'message': 'Please log in to unlike jobs',
        };
      }

      final url = Uri.parse('http://localhost:5000/connect/unlikeJob');

    return _deleteRequest(
        "/unlikeJob", {"user_id": int.parse(userId), "job_post_id": jobId});
  }

  Future<Map<String, dynamic>> fetchJobsForClient(int clientId) async {
    return _getRequest("/displayTask/$clientId");
  }

  Future<List<TaskModel>> fetchUserLikedJobs() async {
    final userId = await getUserId();
    if (userId == null) return [];

    final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
    final allJobsResponse = await _getRequest("/displayTask");

    final likedJobIds = (likedJobsResponse["tasks"] ?? [])
        .map<int>((job) => job["job_post_id"] as int)
        .toSet();

    return (allJobsResponse["tasks"] ?? [])
        .where((job) => likedJobIds.contains(job["job_post_id"]))
        .map((job) => TaskModel.fromJson(job))
        .toList();
  }

  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  ///
  /// Once the user liked the job after saving it, if they open a chat, it will assign the task automatically.
  ///
  /// -Ces
  ///
  Future<Map<String, dynamic>> assignTask(int userId, int taskId) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    return _postRequest(endpoint: "/$apiUrl/assign-task", body: {
      "user_id": userId,
      "task_id": taskId,
    });
  }

  ///
  /// This code is to make the process more efficient when calling APIs. Please do not edit this.
  ///
  /// -Ces
  ///

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
      //print("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      return {"error": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    try {
      String? userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint("Cannot fetch liked jobs: User not logged in");
        return [];
      }

      final url =
          Uri.parse("http://localhost:5000/connect/displayLikedJob/${userId}");

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
            return taskModels;
          }
        }
      }
      return [];
    } catch (e) {
      return {"error": "Request failed: $e"};
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

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }
}
