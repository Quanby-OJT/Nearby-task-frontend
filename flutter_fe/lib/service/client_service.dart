import 'package:flutter_fe/model/tasker_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../config/url_strategy.dart';
import 'api_service.dart';

class ClientServices {
  static String url = apiUrl ?? "http://localhost:5000/connect";
  final dio = Dio();
  static final storage = GetStorage();
  static final token = storage.read('session');
  Future<String?> getUserId() async => storage.read('user_id')?.toString();

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

  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    final token = await AuthService.getSessionToken();
    try {
      // Ensure endpoint starts with a slash if not already
      String formattedEndpoint =
          endpoint.startsWith('/') ? endpoint : '/$endpoint';
      debugPrint('Making GET request to: $url$formattedEndpoint');
      debugPrint('Using token: $token');

      final response = await http.get(
        Uri.parse('$url$formattedEndpoint'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response for $endpoint: ${response.body}");
      return _handleResponse(response);
    } catch (e, stackTrace) {
      debugPrint("API Request Error: $e");
      debugPrint(stackTrace.toString());
      return {"error": "Request failed: $e"};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        debugPrint("API Error Response: $responseBody");
        return {"error": responseBody["error"] ?? "Unknown error"};
      }
    } catch (e) {
      debugPrint("Error parsing response: $e");
      return {"error": "Failed to parse response: $e"};
    }
  }

  Future<Map<String, dynamic>> _putRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
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

  Future<List<TaskerModel>> fetchAllTasker() async {
    final userId = await getUserId();
    if (userId == null) {
      debugPrint("Cannot fetch taskers: User ID is null");
      return [];
    }

    try {
      debugPrint("Fetching all taskers for user ID: $userId");

      // Get all taskers
      final allTaskersResponse = await _getRequest("/client/getAllTaskers");
      if (allTaskersResponse.containsKey("error")) {
        debugPrint(
            "Error fetching all taskers: ${allTaskersResponse["error"]}");
        return [];
      }

      // Get saved/liked taskers
      final savedTaskResponse =
          await _getRequest("/client/getsavedTask/$userId");
      if (savedTaskResponse.containsKey("error")) {
        debugPrint(
            "Error fetching saved taskers: ${savedTaskResponse["error"]}");
        return [];
      }

      // Extract taskers from response
      final allTaskers = allTaskersResponse["taskers"] as List<dynamic>? ?? [];
      debugPrint("All Taskers Count: ${allTaskers.length}");

      if (allTaskers.isEmpty) {
        debugPrint("No taskers returned from API");
        return [];
      }

      // Extract liked tasker IDs
      final likedTaskerIds =
          (savedTaskResponse["liked_tasks"] as List<dynamic>? ?? [])
              .map<int>((task) => task["tasker_id"] as int)
              .toSet();
      debugPrint("Liked Tasker IDs: $likedTaskerIds");

      // Filter out liked taskers and convert to UserModel
      final taskerList = allTaskers
          .where((tasker) {
            final taskerId = tasker["user_id"];
            final isNotLiked =
                taskerId is int && !likedTaskerIds.contains(taskerId);
            if (!isNotLiked) {
              debugPrint("Filtering out already liked tasker: $taskerId");
            }
            return isNotLiked;
          })
          .map((tasker) {
            try {
              return TaskerModel.fromJson(tasker);
            } catch (e) {
              debugPrint("Error parsing tasker: $e");
              debugPrint("Problematic tasker data: $tasker");
              return null;
            }
          })
          .where((tasker) => tasker != null)
          .cast<TaskerModel>()
          .toList();

      debugPrint("Filtered Taskers Count: ${taskerList.length}");
      return taskerList;
    } catch (e, st) {
      debugPrint("Error fetching taskers: $e");
      debugPrint(st.toString());
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

      debugPrint("Client ID: $userId");
      debugPrint("Client ID: $taskId");

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

  Future<Map<String, dynamic>> fetchUserIDImage(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.url}/getUserDocuments/$userId?type=id"),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json"
        },
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint(
          "API Response for /getUserDocuments/$userId: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('user') && data['user'] != null) {
          final user = data['user'];

          if (user.containsKey('document_url') &&
              user['document_url'] != null) {
            return {
              'success': true,
              'url': user['document_url'],
              'status': user['is_valid'] ?? false,
            };
          } else if (user.containsKey('tesda_document_link') &&
              user['tesda_document_link'] != null) {
            return {
              'success': true,
              'url': user['tesda_document_link'],
              'status': user['valid'] ?? false,
            };
          }
        }

        return {'success': false, 'message': 'Image not found'};
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch image. Status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
      return {'success': false, 'message': 'Failed to fetch image'};
    }
  }

  Future<Map<String, dynamic>> submitTaskerRating(
      int taskerId, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('rate-tasker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${storage.read('token')}',
        },
        body: jsonEncode({
          'tasker_id': taskerId,
          'rating': rating,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Failed to submit rating: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting rating: $e',
      };
    }
  }

  Future<List<TaskerModel>> fetchTaskersBySpecialization(
      String specialization) async {
    final userId = await getUserId();
    if (userId == null) {
      debugPrint("Cannot fetch taskers: User ID is null");
      return [];
    }

    try {
      debugPrint("Fetching all taskers for user ID: $userId");

      // Get all taskers
      final allTaskersResponse = await _getRequest(
        '/client/getAllTaskerbySpecialization?specialization=$specialization',
      );
      if (allTaskersResponse.containsKey("error")) {
        debugPrint(
            "Error fetching all taskers: ${allTaskersResponse["error"]}");
        return [];
      }

      // Get saved/liked taskers
      final savedTaskResponse =
          await _getRequest("/client/getsavedTask/$userId");
      if (savedTaskResponse.containsKey("error")) {
        debugPrint(
            "Error fetching saved taskers: ${savedTaskResponse["error"]}");
        return [];
      }

      // Extract taskers from response
      final allTaskers = allTaskersResponse["taskers"] as List<dynamic>? ?? [];
      debugPrint("All Taskers Count: ${allTaskers.length}");

      if (allTaskers.isEmpty) {
        debugPrint("No taskers returned from API");
        return [];
      }

      // Extract liked tasker IDs
      final likedTaskerIds =
          (savedTaskResponse["liked_tasks"] as List<dynamic>? ?? [])
              .map<int>((task) => task["tasker_id"] as int)
              .toSet();
      debugPrint("Liked Tasker IDs: $likedTaskerIds");

      // Filter out liked taskers and convert to UserModel
      final taskerList = allTaskers
          .where((tasker) {
            final taskerId = tasker["user_id"];
            final isNotLiked =
                taskerId is int && !likedTaskerIds.contains(taskerId);
            if (!isNotLiked) {
              debugPrint("Filtering out already liked tasker: $taskerId");
            }
            return isNotLiked;
          })
          .map((tasker) {
            try {
              return TaskerModel.fromJson(tasker);
            } catch (e) {
              debugPrint("Error parsing tasker: $e");
              debugPrint("Problematic tasker data: $tasker");
              return null;
            }
          })
          .where((tasker) => tasker != null)
          .cast<TaskerModel>()
          .toList();

      debugPrint("Filtered Taskers Count: ${taskerList.length}");
      return taskerList;
    } catch (e, st) {
      debugPrint("Error fetching taskers: $e");
      debugPrint(st.toString());
      return [];
    }
  }

  Future<List<String>> fetchSpecializations() async {
    try {
      final response = await dio
          .get('/get-specializations'); // Replace with your API endpoint

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((specialization) => specialization.toString()).toList();
      } else {
        throw Exception('Failed to fetch specializations');
      }
    } catch (e) {
      debugPrint('Error fetching specializations: $e');
      rethrow;
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
}
