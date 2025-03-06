import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:get_storage/get_storage.dart';

class JobPostService {
  final storage = GetStorage();

  Future<Map<String, dynamic>> postJob(TaskModel task) async {
    final url = Uri.parse("http://192.168.110.203:5000/connect/addTask");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(task.toJson()),
      );

      var responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseBody['message'] ?? 'Unable  to Read Backend Response'
        };
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Unable  to Read Backend Response'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error Occured : $e'};
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
          .get(Uri.parse('http://192.168.110.203:5000/connect/displayTask'));

      // Fetch liked jobs
      final likedJobsResponse = await http.get(Uri.parse(

          'http://192.168.110.203:5000/connect/displayLikedJob/${userId}'));


      if (response.statusCode == 200 && likedJobsResponse.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic> likedJobsData =
            jsonDecode(likedJobsResponse.body);

        if (jsonData.containsKey('tasks') &&
            likedJobsData.containsKey('tasks')) {
          final List<dynamic> taskList = jsonData['tasks'];
          final List<dynamic> likedJobs = likedJobsData['tasks'];

          // Extract liked job IDs
          final Set<int> likedJobIds =
              likedJobs.map<int>((job) => job['job_post_id'] as int).toSet();

          // Filter out liked jobs from all jobs
          final List<TaskModel> filteredTasks = taskList
              .map((task) => TaskModel.fromJson(task))
              .where((task) => !likedJobIds.contains(task.id))
              .toList();

          return filteredTasks;
        }
      }
    } catch (e) {
      print("Error fetching jobs: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> saveLikedJob(int jobId) async {
    try {
      final url = Uri.parse('http://192.168.110.203:5000/connect/likeJob');
      String? userId = await getUserId();

      if (userId == null || userId.isEmpty) {
        debugPrint("User not logged in, cannot like job");
        return {
          'success': false,
          'message': 'Please log in to like jobs',
          'requiresLogin': true
        };
      }

      debugPrint("Sending like request with userId: $userId, jobId: $jobId");

      // Updated request body with exact field names
      final requestBody = {
        'user_id': int.parse(userId), // Changed from user_id
        'job_post_id': jobId, // Changed from task_id
        //'status': 1, // Changed from liked:true to status:1
        'created_at':
            DateTime.now().toIso8601String(), // Changed from created_at
      };

      debugPrint("Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseBody = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Job liked successfully'
        };
      } else {
        var responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to like job'
        };
      }
    } catch (e) {
      debugPrint("Exception in saveLikedJob: $e");
      return {'success': false, 'message': 'Error occurred: $e'};
    }
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

      final url = Uri.parse('http://192.168.110.203:5000/connect/unlikeJob');
      debugPrint("Sending unlike request for jobId: $jobId");

      final requestBody = {
        'user_id': int.parse(userId),
        'job_post_id': jobId,
      };

      // Create a new request
      final request = http.Request('DELETE', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(requestBody);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Unlike response status: ${response.statusCode}");
      debugPrint("Unlike response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job unliked successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to unlike job: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint("Error in unlikeJob: $e");
      return {'success': false, 'message': 'Error occurred while unliking job'};
    }
  }

  // Get user ID from GetStorage
  Future<String?> getUserId() async {
    final userId = storage.read('user_id');
    debugPrint("Getting user ID from storage: $userId");

    if (userId == null) {
      debugPrint("No user ID found in storage");
      return null;
    }

    return userId.toString();
  }

  // Get auth token from GetStorage if needed
  Future<String?> getAuthToken() async {
    try {
      return storage.read('authToken');
    } catch (e) {
      debugPrint("Error getting auth token: $e");
      return null;
    }
  }

  // Method to fetch liked jobs for a user
  Future<List<TaskModel>> fetchUserLikedJobs() async {
    try {
      String? userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint("Cannot fetch liked jobs: User not logged in");
        return [];
      }

      final url = Uri.parse(

          "http://192.168.110.203:5000/connect/displayLikedJob/${userId}");

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
          final jobDetailsResponse = await http.get(
              Uri.parse('http://192.168.110.203:5000/connect/displayTask'));

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
      debugPrint("Exception in fetchUserLikedJobs: $e");
      return [];
    }
  }

  Future<void> debugSharedPreferences() async {
    try {
      // Print all keys
      final allData = storage.getKeys();
      debugPrint("All storage keys: $allData");

      // Check if user_id exists and print its value
      final userId = storage.read('user_id');
      debugPrint("Has user_id key: ${userId != null}, Value: $userId");

      // Test storage
      storage.write('test_key', 'test_value');
      debugPrint("Test key set, value: ${storage.read('test_key')}");
    } catch (e) {
      debugPrint("Error debugging storage: $e");
    }
  }
}
