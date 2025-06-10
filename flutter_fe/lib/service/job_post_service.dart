import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/images_model.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/config/url_strategy.dart';

import '../model/client_model.dart';
import '../model/tasker_model.dart';

class JobPostService {
  static String url = apiUrl ?? "https://localhost:5000";
  static final storage = GetStorage();
  static final token = storage.read('session');

  // Cache to track assignments already made in this session
  final Map<String, bool> _assignmentCache = {};

  // Helper to generate cache key for task-tasker pair
  String _getAssignmentCacheKey(int taskId, int taskerId, String userId) {
    return "$taskId-$taskerId-$userId";
  }

  // Public method to update the assignment cache
  void updateAssignmentCache(
      int taskId, int taskerId, bool isAssigned, String userId) {
    String cacheKey = _getAssignmentCacheKey(taskId, taskerId, userId);
    _assignmentCache[cacheKey] = isAssigned;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body.toString());
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      // Ensure the response includes a success flag
      Map<String, dynamic> result = {...responseBody};
      // If the response doesn't have a 'success' key, add it
      if (!result.containsKey('success')) {
        result['success'] = true;
      }
      return result;
    } else {
      // Return error with success flag set to false
      return {
        "success": false,
        "error": responseBody["error"] ?? "Unknown error",
        "message": responseBody["message"] ?? "Failed to process request"
      };
    }
  }

  Future<List<TaskModel>> fetchJobsBySpecialization(
      String specialization) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        debugPrint("User ID is null, returning empty list");
        return [];
      }

      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
      final allJobsResponse = await _getRequest(
          "/displayTaskWithSpecialization?specialization=$specialization");

      debugPrint("Liked Jobs Response: $likedJobsResponse");
      debugPrint("All Jobs Response: $allJobsResponse");

      if (allJobsResponse.containsKey("error")) {
        debugPrint(
            "Error fetching jobs: ${allJobsResponse['error'] ?? 'Invalid response'}");
        return [];
      }

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

  Future<bool> hasTaskEverBeenAssignedToTasker(
      int taskId, int taskerId, userId) async {
    try {
      debugPrint(
          "Checking if task $taskId has ever been assigned to tasker $taskerId, user ID: $userId");

      String cacheKey =
          _getAssignmentCacheKey(taskId, taskerId, userId.toString());
      if (_assignmentCache.containsKey(cacheKey)) {
        return _assignmentCache[cacheKey]!;
      }

      try {
        if (userId != null) {
          final takenTasksResponse = await _getRequest(
              "/task-taken/tasker/$taskerId?userId=$userId&taskId=$taskId");

          if (takenTasksResponse.containsKey('tasks') &&
              takenTasksResponse['tasks'] is List) {
            List<dynamic> takenTasks = takenTasksResponse['tasks'];

            for (var task in takenTasks) {
              debugPrint("Checking task po ${task['id']} for tasker $taskerId");
              final taskIdField =
                  task['post_task_id'] ?? task['task_id'] ?? task['id'];
              if (taskIdField == taskId) {
                debugPrint("Task $taskId is assigned to tasker $taskerId");
                _assignmentCache[cacheKey] = true;
                return true;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking task-taken: $e");
      }

      debugPrint("Task $taskId has never been assigned to tasker $taskerId");
      _assignmentCache[cacheKey] = false;
      return false;
    } catch (e) {
      debugPrint('Error checking task assignment history: $e');
      debugPrintStack();
      return false;
    }
  }

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    debugPrint("Current Session: ${await storage.read('session')}");
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
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$url$endpoint"),
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
      final request = http.Request("DELETE", Uri.parse('$url$endpoint'))
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

  Future<Map<String, dynamic>> _multipartRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required String fileField,
    List<File>? files, // Make file optional
  }) async {
    final token = await AuthService.getSessionToken();
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$url$endpoint'))
        ..headers.addAll({"Authorization": "Bearer $token"});
      body.forEach((key, value) {
        request.fields[key] = value?.toString() ?? '';
      });

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();
          var multipartFile = http.MultipartFile(
            fileField, // Match backend field name
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      } else {
        debugPrint("No files provided");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed. Please Try Again."};
    }
  }

  Future<Map<String, dynamic>> _putRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    debugPrint(body.toString());
    try {
      final response = await http.put(
        Uri.parse('$url$endpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "Request failed. Please Try Again."};
    }
  }

  Future<Map<String, dynamic>> updateJob(
    TaskModel task, {
    required int taskId,
    List<File>? files,
    List<int>? imagesToDelete,
  }) async {
    try {
      debugPrint("Updating task ID: $taskId with data: ${task.toJson()}");
      debugPrint("Files to upload: ${files?.length ?? 0}");
      debugPrint("Images to delete: $imagesToDelete");

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$url/updateTask/$taskId'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Prepare task data
      final taskData = {
        'client_id': task.clientId?.toString(),
        'task_title': task.title,
        'task_description': task.description,
        'proposed_price': task.contactPrice.toString() ?? '0',
        'urgent': (task.urgency == 'Urgent').toString(),
        'remarks': task.remarks,
        'work_type': task.workType,
        'address': task.addressID?.toString(),
        'specialization_id': task.specializationId?.toString() ?? '0',
        'related_specializations':
            jsonEncode(task.relatedSpecializationsIds ?? []),
        'scope': task.scope,
        'task_begin_date': task.taskBeginDate,
        'status': task.status,
        'is_verified': task.isVerifiedDocument?.toString() ?? 'false',
        'image_ids': jsonEncode(task.imageIds ?? []),
      };

      // Remove empty or null fields
      taskData.removeWhere(
          (key, value) => value == null || value == 'null' || value.isEmpty);

      // Add fields to request
      taskData.forEach((key, value) {
        request.fields[key] = value?.toString() ?? '';
      });

      // Add images to delete
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        request.fields['images_to_delete'] = jsonEncode(imagesToDelete);
      }

      // Add image files
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'photos[]', // Match backend field name
                file.path,
                contentType: MediaType('image', file.path.split('.').last),
              ),
            );
          } else {
            debugPrint("File does not exist: ${file.path}");
          }
        }
      }

      debugPrint("Request fields: ${request.fields}");
      debugPrint("Request files: ${request.files.length}");

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final result = jsonDecode(responseData.body) as Map<String, dynamic>;

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${responseData.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': result['message'] ?? 'Task updated successfully',
          'task': result['task'],
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Failed to update task',
          'errors': result['errors'],
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error in updateJob: $e');
      debugPrint(stackTrace.toString());
      return {
        'success': false,
        'error': 'Failed to update task: $e',
      };
    }
  }

  Future<Map<String, dynamic>> postJob(TaskModel task, int userId,
      {List<File>? files}) async {
    try {
      debugPrint("Posting job with data: ${task.toJson()}");
      debugPrint("Files: ${files?.length}");

      var request = http.MultipartRequest('POST', Uri.parse('$url/addTask'));
      request.headers['Authorization'] = 'Bearer $token';

      var taskData = task.toJson();

      if (taskData['duration'] is String) {
        taskData['duration'] =
            int.tryParse(taskData['duration'] as String) ?? 0;
      }

      if (taskData['proposed_price'] == null) {
        taskData['proposed_price'] = 0;
      } else if (taskData['proposed_price'] is String) {
        taskData['proposed_price'] =
            int.tryParse(taskData['proposed_price'] as String) ?? 0;
      }

      taskData.forEach((key, value) {
        if (value != null) {
          if (key == 'related_specializations') {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      request.fields['user_id'] = userId.toString();

      // This will handle multiple file uploads
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'photos[]',
                file.path,
                contentType: MediaType('image', file.path.split('.').last),
              ),
            );
          }
        }
      }

      debugPrint("Posting job with fields: ${request.fields}");
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      var result = jsonDecode(responseData.body) as Map<String, dynamic>;

      return {
        'success':
            result.containsKey('success') ? result['success'] == true : false,
        'message': result['message'] ?? 'Task posted successfully',
        'error': result['error'],
        'task': result['task'],
      };
    } catch (e, stackTrace) {
      debugPrint('Error in postJob: $e');
      debugPrint(stackTrace.toString());
      return {
        'success': false,
        'error': 'Failed to post job: $e',
      };
    }
  }

  Future<List<SpecializationModel>> getSpecializations() async {
    try {
      debugPrint("JobPostService: Fetching specializations from API...");
      final response = await _getRequest("/get-specializations");

      debugPrint(
          "JobPostService: Specializations response: ${response.toString()}");

      if (response["specializations"] != null) {
        final List<dynamic> specializationList =
            response["specializations"] as List;
        debugPrint(
            "JobPostService: Found ${specializationList.length} specializations");

        final List<SpecializationModel> result = specializationList
            .map((item) => SpecializationModel.fromJson(item))
            .toList();

        debugPrint(
            "JobPostService: Successfully mapped specializations to models");
        return result;
      } else {
        debugPrint("JobPostService: No specializations found in response");
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("JobPostService: Error fetching specializations: $e");
      debugPrint("JobPostService: Stack trace: $stackTrace");
      return [];
    }
  }

  Future<List<ImagesModel>> fetchTaskImages(int taskId) async {
    try {
      debugPrint(
          "JobPostService: Fetching images from API for taskId: $taskId");
      final response = await _getRequest("/get-images/$taskId");

      debugPrint("JobPostService: Images response: ${response.toString()}");

      if (response.containsKey("images")) {
        final List<dynamic> imagesList = response["images"] as List;
        final List<ImagesModel> images = imagesList
            .map((item) => ImagesModel.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint("JobPostService: Found ${images.length} images");
        return images;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint("JobPostService: Error fetching images: $e");
      debugPrint("JobPostService: Stack trace: $stackTrace");
      return [];
    }
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

  Future<List<TaskFetch>> taskerTaskInformation(int requestID) async {
    try {
      if (requestID == 0) {
        debugPrint("Invalid requestID: $requestID");
        return [];
      }
      Map<String, dynamic> response =
          await _getRequest("/tasker/taskinformation/$requestID");
      debugPrint("Request Data Retrieved: ${response.toString()}");

      if (response.containsKey('data')) {
        TaskFetch task = TaskFetch.fromJson(response['data']);
        return [task];
      } else {
        debugPrint("Response does not contain a valid 'data' field");
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching request: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<TaskAssignment> fetchTaskInformation(int taskID) async {
    try {
      Map<String, dynamic> response = await _getRequest("/displayTask/$taskID");

      debugPrint("Task Data Retrieved: ${response.toString()}");

      if (response.containsKey("tasks") && response["tasks"] is Map) {
        Map<String, dynamic> taskData =
            response["tasks"] as Map<String, dynamic>;
        debugPrint("Mapped: ${taskData.toString()}");
        return TaskAssignment(
            client: ClientModel.fromJson(taskData['clients']),
            tasker: null,
            task: TaskModel.fromJson(taskData),
            taskStatus: taskData['task_status'] ?? "",
            taskTakenId: taskData['task_taken_id'] ?? 0);
      }

      debugPrint("No valid task data found in response");
      return TaskAssignment(taskTakenId: 0, taskStatus: '');
    } catch (e, stackTrace) {
      debugPrint('Error fetching tasks: $e');
      debugPrintStack(stackTrace: stackTrace);
      return TaskAssignment(taskTakenId: 0, taskStatus: '');
    }
  }

  Future<TaskAssignment?> fetchAssignedTaskInformation(int taskTakenID) async {
    try {
      Map<String, dynamic> response =
          await _getRequest("/display-assigned-task/$taskTakenID");
      debugPrint("Assigned Task Information Retrieved: ${response.toString()}");

      if (response['success']) {
        debugPrint("Mapped: ${response.toString()}");
        return TaskAssignment(
            client: null,
            tasker:
                TaskerModel.fromJson(response['task_information']['tasker']),
            task: TaskModel.fromJson(response['task_information']['post_task']),
            taskStatus: response['task_information']['task_status'],
            taskTakenId: response['task_information']['task_taken_id'],
            taskStatusReason: response['task_information']
                ['reason_for_rejection_or_cancellation']);
      } else if (response.containsKey("error")) {
        debugPrint("Mapped: ${response.toString()}");
        return TaskAssignment(
            client: null,
            tasker: null,
            task: null,
            taskStatus: "Unknown",
            taskTakenId: 0);
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

      // Fetch liked jobs and all jobs
      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");
      final allJobsResponse = await _getRequest("/fetchTasks");

      debugPrint("Liked Jobs Response: $likedJobsResponse");
      debugPrint("All Jobs Response: $allJobsResponse");

      // Check for error in allJobsResponse
      if (allJobsResponse.containsKey("error")) {
        debugPrint(
            "Error fetching jobs: ${allJobsResponse['error'] ?? 'Invalid response'}");
        return [];
      }

      // Validate tasks list
      final tasks = allJobsResponse["taskers"];
      if (tasks == null || tasks is! List) {
        debugPrint(
            "Unexpected response format: 'taskers' is missing or not a list");
        return [];
      }

      // Extract liked task IDs
      final likedTaskIds = (likedJobsResponse["liked_tasks"] as List? ?? [])
          .map((likedTask) => (likedTask["job_post_id"] as int?)?.toString())
          .whereType<String>()
          .toSet();

      debugPrint("Liked task IDs: $likedTaskIds");

      // Filter and map valid tasks
      final validTasks = <TaskModel>[];
      for (var task in tasks) {
        if (task is Map<String, dynamic>) {
          try {
            final taskModel = TaskModel.fromJson(task);
            if (!likedTaskIds.contains(taskModel.id.toString())) {
              validTasks.add(taskModel);
            }
          } catch (e) {
            debugPrint("Error parsing task: $task, error: $e");
          }
        } else {
          debugPrint(
              "Invalid task format, expected Map<String, dynamic>, got: $task");
        }
      }

      debugPrint("Fetched ${validTasks.length} valid tasks");
      return validTasks;
    } catch (e, stackTrace) {
      debugPrint('Error fetching jobs: $e');
      debugPrintStack(stackTrace: stackTrace);
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
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to view your tasks',
        'requiresLogin': true
      };
    }

    final response = await _getRequest("/display-task-for-client/$clientId");

    debugPrint("Client Task Response many: ${response.toString()}");

    if (response.containsKey("success") && response["success"] == true) {
      return response;
    }

    return {};
  }

  Future<Map<String, dynamic>> fetchTasks() async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to view your tasks',
        'requiresLogin': true
      };
    }

    final response = await _getRequest("/fetchTasks/$userId");

    debugPrint("Client fetchTasks Response: ${response.toString()}");

    if (response.containsKey("success") && response["success"] == true) {
      return response;
    }

    return {};
  }

  Future<Map<String, dynamic>> fetchTasksClient() async {
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to view your tasks',
        'requiresLogin': true
      };
    }

    final response = await _getRequest("/fetchTasksClient/$userId");

    debugPrint("Client fetchTasks Response: ${response.toString()}");

    if (response.containsKey("success") && response["success"] == true) {
      return response;
    }

    return {};
  }

  Future<List<TaskModel>> fetchCreatedTasksByClient(int clientId) async {
    try {
      final response = await _getRequest("/display-task-for-client/$clientId");

      debugPrint("Created Tasks Response: $response");

      if (response.containsKey("success") &&
          response["success"] == true &&
          response.containsKey("tasks")) {
        final List<dynamic> tasks = response["tasks"] as List<dynamic>;
        return tasks
            .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint("Falling back to general task endpoint");
        final allTasksResponse = await _getRequest("/displayTask");

        debugPrint("All Tasks Response: ${allTasksResponse.toString()}");

        if (allTasksResponse.containsKey("tasks") &&
            allTasksResponse["tasks"] is List) {
          final List<dynamic> allTasks =
              allTasksResponse["tasks"] as List<dynamic>;

          final filteredTasks = allTasks.where((task) {
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

  Future<List<TaskModel>> fetchAssignTasksByClient(int clientId) async {
    try {
      final response =
          await _getRequest("/display-task-for-client-available/$clientId");

      debugPrint("Created Tasks Response: $response");

      if (response.containsKey("success") &&
          response["success"] == true &&
          response.containsKey("tasks")) {
        final List<dynamic> tasks = response["tasks"] as List<dynamic>;
        return tasks
            .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint("Falling back to general task endpoint");
        final allTasksResponse = await _getRequest("/displayTask");

        if (allTasksResponse.containsKey("tasks") &&
            allTasksResponse["tasks"] is List) {
          final List<dynamic> allTasks =
              allTasksResponse["tasks"] as List<dynamic>;

          final filteredTasks = allTasks.where((task) {
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
      debugPrint("Exception in fetchCreatedTasksByClient sample : $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<List<TaskModel>> fetchUserLikedJobs() async {
    try {
      String? userId = await getUserId();

      final likedJobsResponse = await _getRequest("/displayLikedJob/$userId");

      if (likedJobsResponse.containsKey("liked_tasks")) {
        final likedTasks = likedJobsResponse["liked_tasks"];
        if (likedTasks is List<dynamic>) {
          final Set<int> likedJobIds = likedTasks
              .where((job) => job["job_post_id"] != null)
              .map<int>((job) {
            final jobPostId = job["job_post_id"];
            return jobPostId is int
                ? jobPostId
                : int.parse(jobPostId.toString());
          }).toSet();

          List<TaskModel> likedTasksList = [];
          for (int jobId in likedJobIds) {
            final taskResponse = await _getRequest("/displayTask/$jobId");

            if (taskResponse.containsKey("tasks") &&
                taskResponse["tasks"] != null) {
              final taskData = Map<String, dynamic>.from(taskResponse["tasks"]);
              if (taskData["address"] is String) {
                taskData["address"] = null;
              }

              final task = TaskModel.fromJson(taskData);
              likedTasksList.add(task);
            }
          }

          return likedTasksList;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("Error: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<String?> getUserId() async => storage.read('user_id')?.toString();
  Future<bool> isTaskAssignedToTasker(int taskId, int taskerId) async {
    try {
      debugPrint("Checking if task $taskId is assigned to tasker $taskerId");

      try {
        final takenTasksResponse =
            await _getRequest("/task-taken/tasker/$taskerId");

        if (takenTasksResponse.containsKey('data') &&
            takenTasksResponse['data'] is List) {
          List<dynamic> takenTasks = takenTasksResponse['data'];

          for (var task in takenTasks) {
            final taskIdField =
                task['post_task_id'] ?? task['task_id'] ?? task['id'];
            if (taskIdField == taskId) {
              debugPrint(
                  "Task $taskId is already assigned to tasker $taskerId (from task-taken)");
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking task-taken: $e");
        // Continue with other checks
      }

      debugPrint("Task $taskId is not assigned to tasker $taskerId");
      return false;
    } catch (e) {
      debugPrint('Error checking task assignment: $e');
      debugPrintStack();
      // In case of error, return true to prevent potential duplicate assignments
      return true;
    }
  }

  Future<bool> checkExistingAssignment(int taskId, int taskerId) async {
    try {
      debugPrint(
          "Checking for existing assignment between task $taskId and tasker $taskerId");

      // First approach: Direct database check
      final response = await _postRequest(
          endpoint: "/check-task-assignment/$taskId/$taskerId",
          body: {"tasker_id": taskerId, "task_id": taskId});

      // Log the response for debugging
      debugPrint("Check assignment response: $response");

      if (response.containsKey('exists') && response['exists'] == true) {
        debugPrint("Found existing assignment in direct check");
        return true;
      }

      debugPrint(
          "No existing assignment found for task $taskId and tasker $taskerId");
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error checking existing assignment: $e');
      debugPrintStack(stackTrace: stackTrace);
      // In case of error, return false and log the error
      // This is safer than returning true as it won't block valid assignments
      return false;
    }
  }

  Future<Map<String, dynamic>> assignTask(
      int taskId, int clientId, int taskerId, String role,
      {int? daysAvailable, String? availableDate}) async {
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
    debugPrint("Role poo: $role");

    return _postRequest(endpoint: "/assign-task", body: {
      "tasker_id": taskerId,
      "client_id": clientId,
      "task_id": taskId,
      "role": role,
      "task_status": "Pending",
      "days_available": daysAvailable,
    });
  }

  Future<Map<String, dynamic>> updateNotification(
      int taskTakenId, int userId) async {
    try {
      debugPrint("Updating notification with ID: $taskTakenId and $userId");
      final response = await http.put(
        Uri.parse('$url/updateNotification/$taskTakenId?userId=$userId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      print("API Response for updateNotification: ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error accepting task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateRequest(
      int taskTakenId, String value, String role,
      {String? rejectionReason}) async {
    try {
      int clientId = await storage.read('user_id');
      debugPrint(
          "Accepting task with ID: $taskTakenId with the task status of: $value");
      return await _putRequest(endpoint: '/update-request/$taskTakenId', body: {
        "value": value,
        "role": role,
        "client_id": clientId,
        "rejection_reason": rejectionReason
      });
    } catch (e, stackTrace) {
      debugPrint('Error accepting task: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDispute(int taskTakenId) async {
    try {
      return await _getRequest('/get-a-dispute/$taskTakenId');
    } catch (e, stackTrace) {
      debugPrint('Error accepting task: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {
        'success': false,
        'error':
            'An Error Occurred while displaying your task information. Please Try Again'
      };
    }
  }

  Future<Map<String, dynamic>> raiseADispute(
      int taskTakenId,
      String value,
      String role,
      List<File> imageEvidence,
      String disputeReason,
      String disputeDetails) async {
    try {
      int userId = await storage.read('user_id');

      if (imageEvidence.length > 10) {
        return {
          'success': false,
          'error': 'Maximum Number of Pictures is only 10.'
        };
      }

      if (imageEvidence.isNotEmpty) {
        return await _multipartRequest(
            endpoint: '/update-request/$taskTakenId',
            body: {
              "value": value,
              "role": role,
              "user_id": userId,
              "reason_for_dispute": disputeReason,
              "dispute_details": disputeDetails
            },
            fileField: 'imageEvidence',
            files: imageEvidence);
      }
      // Fallback to regular PUT request if no file
      return await _putRequest(endpoint: '/update-request/$taskTakenId', body: {
        "value": value,
        "role": role,
        "user_id": userId,
        "reason_for_dispute": disputeReason,
        "dispute_details": disputeDetails
      });
    } catch (e) {
      debugPrint('Error raising a dispute: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> rateTheTasker(
      int taskTakenId, int taskerId, int rating, String feedback) async {
    try {
      debugPrint(
          "Rating the tasker with rating: $rating and feedback: $feedback");
      return await _postRequest(endpoint: '/rate-the-tasker', body: {
        "task_taken_id": taskTakenId,
        "tasker_id": taskerId,
        "rating": rating,
        "feedback": feedback
      });
    } catch (e) {
      debugPrint('Error rating the tasker: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getClientFeedback(int taskTakenId) async {
    try {
      return await _getRequest('/get-client-feedback/$taskTakenId');
    } catch (e) {
      debugPrint('Error getting client feedback: $e');
      debugPrintStack();
      return {
        'success': false,
        'error':
            'An error occured while retrieving your feedback. Please Try Again.'
      };
    }
  }

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

  Future<Map<String, dynamic>> requestTask(int taskId, int taskerId) async {
    try {
      // First check if task is already assigned
      final taskResponse = await http.get(
        Uri.parse('$apiUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer ${storage.read('token')}',
        },
      );

      if (taskResponse.statusCode == 200) {
        final taskData = json.decode(taskResponse.body);
        if (taskData['status'] == 'Assigned' ||
            taskData['status'] == 'In Progress' ||
            taskData['status'] == 'Completed') {
          return {
            'success': false,
            'message':
                'This task has already been ${taskData['status'].toLowerCase()}',
          };
        }
      }

      // Proceed with task assignment if not already assigned
      final response = await http.post(
        Uri.parse('$apiUrl/requestTask/$taskId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"tasker_id": taskerId}),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error requesting task: $e');
      debugPrintStack();
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Future<Map<String, dynamic>> updateTask(
  //     int taskId, Map<String, dynamic> taskData,
  //     {List<File>? photos,
  //     List<int>? imagesToDelete,
  //     List<int>? existingImageIds}) async {
  //   try {
  //     return await _multipartRequest(
  //         endpoint: '/updateTask/$taskId',
  //         body: taskData,
  //         fileField: 'photo',
  //         files: photos);
  //   } catch (e) {
  //     debugPrint('Error updating task: $e');
  //     debugPrintStack();
  //     return {'success': false, 'error': 'Error: $e'};
  //   }
  // }

  Future<Map<String, dynamic>> updateTask(
    int taskId,
    TaskModel task, {
    List<File>? photos,
    List<int>? imagesToDelete,
  }) async {
    try {
      var request =
          http.MultipartRequest('PUT', Uri.parse('$updateTask/$taskId'));
      request.headers['Authorization'] = 'Bearer $token';

      var taskData = task.toJson();
      taskData.forEach((key, value) {
        if (value != null) {
          if (key == 'related_specializations' || key == 'image_ids') {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (photos != null && photos.isNotEmpty) {
        for (var file in photos) {
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'photos[]',
                file.path,
                contentType: MediaType('image', file.path.split('.').last),
              ),
            );
          }
        }
      }

      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        request.fields['images_to_delete'] = jsonEncode(imagesToDelete);
      }

      debugPrint("Updating task with fields: ${request.fields}");
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      var result = jsonDecode(responseData.body) as Map<String, dynamic>;

      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Task updated successfully',
        'error': result['error'],
        'task': result['task'],
      };
    } catch (e, stackTrace) {
      debugPrint('Error updating task: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {
        'success': false,
        'error': 'Failed to update task: $e',
      };
    }
  }

  // Method to disable a task
  Future<Map<String, dynamic>> disableTask(int taskId,
      [String status = "cancelled"]) async {
    try {
      debugPrint("Disabling task with ID: $taskId with status: $status");
      final response = await http.put(
        Uri.parse('$url/disableTask/$taskId'),
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
        Uri.parse('$url/deleteTask/$taskId'),
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

  // Method to check if a task is assigned to anyone
  Future<bool> isTaskAssigned(int taskId, int taskerId) async {
    try {
      debugPrint("Checking if task $taskId is assigned to anyone");

      // First approach: Check in task-assignments
      final response =
          await _getRequest("/check-task-assignment/$taskId/$taskerId");

      if (response.containsKey('assignments') &&
          response['assignments'] is List) {
        List<dynamic> assignments = response['assignments'];

        // Check if this task is assigned to anyone
        for (var assignment in assignments) {
          if (assignment['task_id'] == taskId ||
              assignment['post_task_id'] == taskId) {
            debugPrint(
                "Task $taskId is assigned to someone (from assignments)");
            return true;
          }
        }
      }

      // Second approach: Check in task-taken with tasker ID
      try {
        final userId = await getUserId();
        if (userId != null) {
          final takenTasksResponse =
              await _getRequest("/task-taken/tasker/$userId");

          if (takenTasksResponse.containsKey('data') &&
              takenTasksResponse['data'] is List) {
            List<dynamic> takenTasks = takenTasksResponse['data'];

            for (var task in takenTasks) {
              final taskIdField =
                  task['post_task_id'] ?? task['task_id'] ?? task['id'];
              if (taskIdField == taskId) {
                debugPrint(
                    "Task $taskId is assigned to someone (from task-taken)");
                return true;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking task-taken: $e");
        // Continue with other checks
      }

      debugPrint("Task $taskId is not assigned to anyone");
      return false;
    } catch (e) {
      debugPrint('Error checking if task is assigned: $e');
      debugPrintStack();
      return false;
    }
  }
}
