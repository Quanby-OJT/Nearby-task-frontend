import 'dart:io';

import 'package:flutter_fe/config/url_strategy.dart';
import 'package:flutter_fe/model/timeSlot.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';
import 'package:flutter_fe/model/tasker_feedback.dart';

import '../model/address.dart';
import '../model/tasker_model.dart';
class TaskerService {
  static final storage = GetStorage();
  static final String url = apiUrl ?? "https://localhost:5000";

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

  Future<Map<String, dynamic>> _deleteRequest(String endpoint, Map<String, dynamic> body) async {
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

  Future<Map<String, dynamic>> getTaskerProfile(int taskerId) async {
    try {
      final token = await AuthService.getSessionToken();
      final response = await http.get(
        Uri.parse('$url/tasker-profile/$taskerId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {"error": "Failed to fetch tasker profile: $e"};
    }
  }

  Future<Map<String, dynamic>> getDocumentLink(int taskerId) async {
    try {
      final token = await AuthService.getSessionToken();
      final response = await http.get(
        Uri.parse('$url/document-link/$taskerId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {"error": "Failed to fetch document link: $e"};
    }
  }

  Future<Map<String, dynamic>> updateTasker(List<File>? taskerImages, List<File>? taskerDocuments, TaskerModel tasker) async {
    final token = await AuthService.getSessionToken();
    final id = await storage.read("user_id");
    final role = await storage.read("role");
    final uri = Uri.parse('$url/update-tasker/$id');

    if (taskerImages != null || taskerDocuments != null) {
      // Multipart request
      var request = http.MultipartRequest('PUT', uri)
        ..headers["Authorization"] = "Bearer $token"
        ..fields['tasker'] = jsonEncode({...tasker.toJson(), "role": role});

      if (taskerImages != null) {
        for (var file in taskerImages) {
          request.files.add(await http.MultipartFile.fromPath(
            'tasker_images', // This should match the backend's expected field name
            file.path,
          ));
        }
      }

      if (taskerDocuments != null) {
        for (var file in taskerDocuments) {
          request.files.add(await http.MultipartFile.fromPath(
            'tasker_documents', // This should match the backend's expected field name
            file.path,
          ));
        }
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        return _handleResponse(response);
      } catch (e) {
        return {"error": "Request failed: $e"};
      }
    } else {
      // Standard PUT request
      return await _putRequest(
        endpoint: '/update-user/$id',
        body: tasker.toJson(),
      );
    }
  }

  ///
  /// These four(4) methods are meant to tasker schedule CRUD.
  ///
  /// -----START OF TASKER SCHEDULE CRUD METHODS-----
  ///
  Future<List<TaskerFeedback>> getTaskerFeedback(int taskerId) async {
    try {
      var response = await _getRequest("/get-taskers-feedback/$taskerId");
      if (response.containsKey("tasker_feedback")) {
        List<TaskerFeedback> feedbacks = [];
        for (var feedback in response["tasker_feedback"]) {
          feedbacks.add(TaskerFeedback.fromJson(feedback));
        }
        debugPrint("Feedback Data: $feedbacks");
        return feedbacks;
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint("Error getting tasker feedback: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<String> setTaskerSchedule(List<Map<String, dynamic>> schedule) async {
    try {
      final taskerId = await storage.read("user_id");
      if (taskerId == null) {
        return "Error: Tasker ID not found";
      }

      final response = await http.post(
        Uri.parse('$url/set-tasker-schedule'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"tasker_id": taskerId, "schedule": schedule}),
      );

      if (response.statusCode == 200) {
        return "Schedule set successfully";
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? "Failed to set schedule";
        return "Error: $error";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> editTaskerSchedule(int id, Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.put(
        Uri.parse('$url/edit-tasker-schedule/$id'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "tasker_id": await storage.read("user_id"),
          "schedule": scheduleData,
        }),
      );

      if (response.statusCode == 200) {
        return "Schedule edited successfully";
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? "Failed to edit schedule";
        return "Error: $error";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> deleteTaskerSchedule(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$url/delete-tasker-schedule/$id'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return "Schedule deleted successfully";
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? "Failed to delete schedule";
        return "Error: $error";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<Map<DateTime, List<TimeSlot>>> getTaskerSchedule() async {
    try {
      final taskerId = await storage.read("user_id");
      if (taskerId == null) {
        debugPrint("Tasker ID not found");
        return {};
      }

      final response = await http.get(
        Uri.parse('$url/get-tasker-schedule/$taskerId'),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");
        if (data.containsKey("data")) {
          final List<dynamic> scheduleData = data["data"];
          final Map<DateTime, List<TimeSlot>> schedule = {};

          for (var item in scheduleData) {
            final taskerScheduler = TaskerScheduler.fromJson(item);
            final date = DateTime.parse(taskerScheduler.dateScheduled);
            final timeSlot = TimeSlot(
              id: taskerScheduler.id,
              tasker_id: taskerScheduler.tasker_id,
              startTime: _parseTime(taskerScheduler.startTime),
              endTime: _parseTime(taskerScheduler.endTime),
              isAvailable: taskerScheduler.isAvailable,
            );

            final dateKey = DateTime(date.year, date.month, date.day);
            schedule[dateKey] = schedule[dateKey] ?? [];
            schedule[dateKey]!.add(timeSlot);
          }

          debugPrint("Loaded schedules: $schedule");
          return schedule;
        }
        debugPrint("No schedules found in response: $data");
        return {};
      } else {
        debugPrint("Error fetching schedule: ${response.body}");
        return {};
      }
    } catch (e) {
      debugPrint("Error getting tasker schedule: $e");
      return {};
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
  ///
  /// ------END OF TASKER SCHEDULE CRUD METHODS------
  ///

  Future<Map<String, dynamic>> getRelatedSkills(String specialization) async {
    try{
      return await _getRequest("/all-relevant-skills/$specialization");
    }catch(e, stackTrace){
      debugPrint("Error getting related skills: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "Failed to get related skills"};
    }
  }

  // Helper method for standard PUT requests (if not already existing)
  static Future<Map<String, dynamic>> _putRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final token = await AuthService.getSessionToken();
    final response = await http.put(Uri.parse("$url$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }
}


