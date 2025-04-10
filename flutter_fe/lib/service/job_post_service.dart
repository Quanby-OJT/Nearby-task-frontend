import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:get_storage/get_storage.dart';

import '../model/client_model.dart';
import '../model/tasker_model.dart';

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

  Future<Map<String, dynamic>> postJob(TaskModel task, int userId) async {
    try {
      // Log the request for debugging
      debugPrint("Posting job with data: ${task.toJson()}");

      // Make sure duration and proposed_price are properly formatted
      var taskData = task.toJson();

      // Ensure duration is an integer
      if (taskData['duration'] is String) {
        taskData['duration'] =
            int.tryParse(taskData['duration'] as String) ?? 0;
      }

      // Ensure proposed_price is an integer
      if (taskData['proposed_price'] == null) {
        taskData['proposed_price'] = 0;
      } else if (taskData['proposed_price'] is String) {
        taskData['proposed_price'] =
            int.tryParse(taskData['proposed_price'] as String) ?? 0;
      }

      // Print the final data being sent
      debugPrint("Posting job with data: ${taskData}");

      Map<String, dynamic> response = await _postRequest(
        endpoint: "/addTask",
        body: {...taskData, "user_id": userId},
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

    debugPrint("Specializations Response: ${response.toString()}");
    if (response["specializations"] != null) {
      return (response["specializations"] as List)
          .map((item) => SpecializationModel.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<ClientRequestModel> fetchRequestInformation(int requestID) async {
    try {
      Map<String, dynamic> response =
          await _getRequest("/displayRequest/$requestID");
      debugPrint("Request Data Retrieved: ${response.toString()}");

      if (response.containsKey("request") && response["request"] is Map) {
        Map<String, dynamic> request =
            response["request"] as Map<String, dynamic>;
        debugPrint("Mapped: ${request.toString()}");
        return ClientRequestModel.fromJson(request);
      } else {
        debugPrint("Response does not contain a valid 'request' map");
        return ClientRequestModel();
      }
    } catch (e) {
      debugPrint('Error fetching request: $e');
      debugPrintStack();
      return ClientRequestModel();
    }
  }

  Future<TaskModel?> fetchTaskInformation(int taskID) async {
    try {
      Map<String, dynamic> response = await _getRequest("/displayTask/$taskID");
      //debugPrint("Assigned Task Information Retrieved: ${response.toString()}");

      // Check if response contains the "tasks" key and it's a Map
      if (response.containsKey("tasks") && response["tasks"] is Map) {
        Map<String, dynamic> taskData =
            response["tasks"] as Map<String, dynamic>;
        debugPrint("Mapped: ${taskData.toString()}");
        return TaskAssignment(
          client: ClientModel.fromJson(taskData['clients']),
          tasker: null,
          task: TaskModel.fromJson(taskData),
          taskStatus: taskData['task_status'] ?? "",
          taskTakenId: taskData['task_taken_id'] ?? 0
        );
      }

      // Return null if no tasks found or invalid format
      debugPrint("No valid task data found in response");
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error fetching tasks: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<TaskAssignment?> fetchAssignedTaskInformation(int taskTakenID) async {
    try {
      Map<String, dynamic> response = await _getRequest("/display-assigned-task/$taskTakenID");
      debugPrint("Assigned Task Information Retrieved: ${response.toString()}");

      // Check if response is not empty and is a Map
      if (response['success']) {
        debugPrint("Mapped: ${response.toString()}");
        return TaskAssignment(
          client: null,
          tasker: TaskerModel.fromJson(response['task_information']['tasker']),
          task: TaskModel.fromJson(response['task_information']['post_task']),
          taskStatus: response['task_information']['task_status'],
          taskTakenId: response['task_information']['task_taken_id'],
          taskStatusReason: response['task_information']['reason_for_rejection_or_cancellation']
        );
      }else if(response.containsKey("error")){
        debugPrint("Mapped: ${response.toString()}");
        return TaskAssignment(
          client: null,
          tasker: null,
          task: null,
          taskStatus: "Unknown",
          taskTakenId: 0
        );
      }

      // Return null if no valid data found
      debugPrint("No valid task data found in response");
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error fetching tasks: $e');
      debugPrintStack(stackTrace: stackTrace);
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

  Future<List<TaskModel>> fetchCreatedTasksByClient(int clientId) async {
    try {
      // First try with the updated API endpoint
      final response = await _getRequest("/getCreatedTaskByClient/$clientId");

      // Log response for debugging
      debugPrint("Created Tasks Response: $response");

      if (response.containsKey("success") &&
          response["success"] == true &&
          response.containsKey("tasks")) {
        final List<dynamic> tasks = response["tasks"] as List<dynamic>;
        return tasks
            .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
            .toList();
      } else {
        // If the new endpoint fails, fall back to the general task endpoint
        // and filter by client_id
        debugPrint("Falling back to general task endpoint");
        final allTasksResponse = await _getRequest("/displayTask");

        if (allTasksResponse.containsKey("tasks") &&
            allTasksResponse["tasks"] is List) {
          final List<dynamic> allTasks =
              allTasksResponse["tasks"] as List<dynamic>;

          // Filter tasks by client_id
          final filteredTasks = allTasks.where((task) {
            // Check if task is a Map and has client_id that matches
            return task is Map<String, dynamic> &&
                task.containsKey("client_id") &&
                task["client_id"] == clientId;
          }).toList();

          return filteredTasks
              .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
              .toList();
        }

        debugPrint(
            "Error or empty response: ${response['error'] ?? 'No tasks found'}");
        return [];
      }
    } catch (e, st) {
      debugPrint("Exception in fetchCreatedTasksByClient: $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  //Not sure if this will work. Needs more debugging.
  Future<List<TaskModel>> fetchUserLikedJobs() async {
    try {
      String? userId = await getUserId();

      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
      final allJobsResponse = await _getRequest("/displayTask");
      debugPrint(likedJobsResponse.toString());

      final allJobsList = (allJobsResponse["tasks"] as List<dynamic>?)
              ?.map((job) => TaskModel.fromJson(job))
              .toList() ??
          [];

      if (likedJobsResponse.containsKey("liked_tasks")) {
        final likedJobs = likedJobsResponse["liked_tasks"] as List<dynamic>;
        debugPrint("Raw liked jobs: $likedJobs");
        final Set<int> likedJobIds = likedJobs
            .where((job) => job["job_post_id"] != null)
            .map<int>((job) => (job["job_post_id"] is int
                ? job["job_post_id"]
                : int.parse(job["job_post_id"].toString())) as int)
            .toSet();

        debugPrint("Liked Jobs Response ${likedJobsResponse.toString()}");
        debugPrint("All Jobs: ${likedJobIds.toString()}");

        final filteredJobs =
            allJobsList.where((job) => likedJobIds.contains(job.id)).toList();

        debugPrint("Filtered Jobs: ${filteredJobs.toString()}");
        return filteredJobs;
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<String?> getUserId() async => storage.read('user_id')?.toString();

  Future<Map<String, dynamic>> fetchIsApplied(
      int? taskId, int? clientId, int? taskerId) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    debugPrint("Sending task request...");
    debugPrint("Task ID: $taskId, Client ID: $clientId, Tasker ID: $taskerId");

    final response = await _getRequest(
        "/fetchIsApplied?task_id=$taskId&client_id=$clientId&tasker_id=$taskerId");
    return response;
  }

  Future<Map<String, dynamic>> acceptRequest(int taskTakenId) async {
    try {
      debugPrint("Accepting task with ID: $taskTakenId");
      final response = await http.put(
        Uri.parse('$apiUrl/acceptRequest/$taskTakenId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      print("API Response for acceptRequest: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error accepting task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> assignTask(
      int taskId, int clientId, int taskerId) async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    debugPrint("Sending task request...");
    debugPrint("Task ID: $taskId, Client ID: $clientId, Tasker ID: $taskerId");

    return _postRequest(endpoint: "/assign-task", body: {
      "tasker_id": taskerId,
      "client_id": clientId,
      "task_id": taskId,
      // Backend expects task_status field, not status
      "task_status": "Pending"
    });
  }

  // Method to update a task
  Future<Map<String, dynamic>> updateTask(
      int taskId, Map<String, dynamic> taskData) async {
    try {
      debugPrint("Updating task with ID: $taskId");
      final response = await http.put(
        Uri.parse('$apiUrl/updateTask/$taskId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(taskData),
      );

      print("API Response for updateTask: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error updating task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Method to disable a task
  Future<Map<String, dynamic>> disableTask(int taskId,
      [String status = "cancelled"]) async {
    try {
      debugPrint("Disabling task with ID: $taskId with status: $status");
      final response = await http.put(
        Uri.parse('$apiUrl/disableTask/$taskId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"status": status}),
      );

      print("API Response for disableTask: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error disabling task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Method to fetch valid task statuses
  Future<List<String>> fetchValidTaskStatuses() async {
    try {
      final response = await _getRequest("/task-statuses");

      if (response.containsKey("statuses") && response["statuses"] is List) {
        return (response["statuses"] as List).map((s) => s.toString()).toList();
      }

      // If we can't get the valid statuses, return some common ones
      return ["ACTIVE", "INACTIVE", "COMPLETED", "CANCELLED"];
    } catch (e) {
      debugPrint('Error fetching valid task statuses: $e');
      // Return default values if we can't get them from the server
      return ["ACTIVE", "INACTIVE", "COMPLETED", "CANCELLED"];
    }
  }

  // Method to delete a task
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      debugPrint("Deleting task with ID: $taskId");
      final token = await AuthService.getSessionToken();
      final response = await http.delete(
        Uri.parse('$apiUrl/deleteTask/$taskId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      print("API Response for deleteTask: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }
}
