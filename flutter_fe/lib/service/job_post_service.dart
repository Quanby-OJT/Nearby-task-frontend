import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:get_storage/get_storage.dart';

class JobPostService {
  static final String apiUrl = "http://10.0.2.2:5000/connect";
  static final storage = GetStorage();

  Future<Map<String, dynamic>> postJob(TaskModel task, int userId) async {
    final url = Uri.parse("$apiUrl/addTask");
    final String token = await AuthService.getSessionToken();

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Access-Control-Allow-Credentials": "true"
        },
        body: jsonEncode({
          ...task.toJson(),  // Spreads existing task properties
          "user_id": userId   // Adds userId to the payload
        }),
      );

      var responseBody = jsonDecode(response.body);
      debugPrint(responseBody.toString());
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseBody['message'] ?? 'Task Posted Successfully.'
        };
      } else if (response.statusCode == 400) {
        List<dynamic> validationErrors = responseBody['errors'];

        // Extracting only the error messages
        List errorMessages = validationErrors.map((error) => error['msg']).toList();

        return {
          'success': false,
          'errors': errorMessages.join('\n') // Join messages into a single string
        };
      }
      else {
        return {
          'success': false,
          'message':
              responseBody['error'] ?? 'Error while posting job. Please Try Again.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error Occured : $e'};
    }
  }

  Future<List<SpecializationModel>> getSpecializations() async {
    final String token = await AuthService.getSessionToken();
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/get-specializations'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Access-Control-Allow-Credentials": "true"
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        if (decodedData.containsKey('specializations')) {
          List<dynamic> specializationList = decodedData['specializations'];

          return specializationList
              .map((item) => SpecializationModel.fromJson(item))
              .toList();
        }
      }
      throw Exception("Failed to retrieve specializations");
    } catch (e) {
      throw Exception("An Error Occurred while Retrieving Specializations: $e");
    }
  }

  Future<List<TaskModel>> fetchAllJobs() async {
    try {
      final userId = await getUserId();
      final String token = await AuthService.getSessionToken();

      if (userId == null) {
        debugPrint("You must be logged in first.");
        return [];
      }

      // Fetch all jobs
      final response = await http.get(
        Uri.parse('$apiUrl/displayTask'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      debugPrint(response.body);

      // Fetch liked jobs
      final likedJobsResponse = await http.get(
        Uri.parse('$apiUrl/displayLikedJob/$userId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      debugPrint(likedJobsResponse.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> taskList = jsonData.containsKey('tasks') ? jsonData['tasks'] : [];

        // Handle empty liked jobs safely
        Set<int> likedJobIds = {};
        if (likedJobsResponse.statusCode == 200) {
          final Map<String, dynamic> likedJobsData = jsonDecode(likedJobsResponse.body);
          final List<dynamic> likedJobs = likedJobsData.containsKey('liked_tasks') ? likedJobsData['liked_tasks'] : [];

          // Convert liked job IDs to a set
          likedJobIds = likedJobs.map<int>((job) => job['job_post_id'] as int).toSet();
        }

        // Convert tasks to TaskModel and ensure all tasks are displayed
        final List<TaskModel> allTasks = taskList.map((task) => TaskModel.fromJson(task)).toList();

        return allTasks;
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching jobs: $e");
      debugPrint(stackTrace.toString());
    }

    return [];
  }


  Future<Map<String, dynamic>> saveLikedJob(int jobId) async {
    try {
      final url = Uri.parse('$apiUrl/likeJob');
      String? userId = await getUserId();
      final String token = await AuthService.getSessionToken();

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
          "Authorization": "Bearer $token"
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

      final url = Uri.parse('$apiUrl/unlikeJob');
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

  Future<Map<String, dynamic>> fetchJobsforClient(int clientId) async {
    var response = await http.get(
        Uri.parse("$apiUrl/displayTask/$clientId"),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json"
        }
    );

    debugPrint("Response Body: ${response.body}");

    try {
      final Map<String, dynamic> taskData = jsonDecode(response.body); // Decode JSON properly

      if (response.statusCode == 200) {
        return {"client_task": taskData['tasks'] ?? []}; // Ensure 'data' exists, fallback to an empty list
      } else {
        return {"error": taskData['error'] ?? "Unknown error"}; // Handle missing error key
      }
    } catch (e) {
      return {"error": "Failed to parse JSON: ${e.toString()}"}; // Handle JSON decoding errors
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
      String? token = await storage.read('session');
      if (userId == null || userId.isEmpty) {
        debugPrint("Cannot fetch liked jobs: User not logged in");
        return [];
      }

      final url = Uri.parse("$apiUrl/displayLikedJob/${userId}");
      debugPrint("Fetching liked jobs from: $url");

      final response = await http.get(
          url,
        headers: {
            "Authorization": "Bearer $token"
        }
      );
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
              Uri.parse('http://192.168.110.144:5000/connect/displayTask'));

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
