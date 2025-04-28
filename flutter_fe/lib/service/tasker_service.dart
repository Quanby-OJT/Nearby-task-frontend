import 'dart:io';

import 'package:flutter_fe/config/url_strategy.dart';
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
  static final String url = apiUrl ?? "http://localhost:5000/connect";

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

  Future<Map<String, dynamic>> updateTaskerInfoWithFiles(
      TaskerModel tasker, AddressModel address, File? file, File? image) async {
    try {
      String? token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$url/update-tasker-login-with-file/${tasker.id}"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add fields with null-safe defaults, matching backend expectations
      request.fields.addAll({
        "user_id": tasker.id.toString(),
        "tasker_id":
            tasker.id.toString(), // Assuming tasker.id is used for both
        "first_name": tasker.user?.firstName ?? '',
        "middle_name": tasker.user?.middleName ?? '',
        "last_name": tasker.user?.lastName ?? '',
        "email": tasker.user?.email ?? '',
        "gender": tasker.user?.gender ?? '',
        "contact": tasker.user?.contact ?? '',
        "birthdate": tasker.user?.birthdate ?? '',
        "bio": tasker.bio ?? '',
        "specialization": tasker.specialization ?? '',
        "pay_period": tasker.payPeriod ?? '',
        "skills": tasker.skills ?? '',
        "availability": tasker.availability.toString(),
        "wage_per_hour": tasker.wage.toString(),
        "street_address": address.streetAddress ?? '',
        "barangay": address.barangay ?? '',
        "city": address.city ?? '',
        "province": address.province ?? '',
        "postal_code": address.postalCode ?? '',
        "country": address.country ?? '',
        // Add social_media_links if needed
        "social_media_links": '{}',
      });

      debugPrint('Request fields: ${request.fields}');

      // Add profile image (named "image" to match backend)
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image", // Match backend field name
            image.path,
            filename:
                "profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg",
          ),
        );
      }

      // Add document file (named "document" to match backend)
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "documents", // Match backend field name
            file.path,
            filename: "document_${DateTime.now().millisecondsSinceEpoch}.pdf",
          ),
        );
      }

      debugPrint('Request files: ${request.files}');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode == 200) {
        return {
          "message":
              data["message"] ?? "Tasker information updated successfully!",
          "profile_picture": data["profile_picture"],
          "tesda_document_link": data["tesda_document_link"],
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (data['error'] is String) {
          errorMessage = data['error'];
        } else if (data['error'] is Map) {
          errorMessage = data['error']['message'] ?? "Invalid data provided.";
        }
        return {
          "errors":
              errorMessage.isNotEmpty ? errorMessage : "Invalid data provided."
        };
      } else {
        return {
          "errors": data["error"] ?? "An unexpected server error occurred."
        };
      }
    } catch (e) {
      debugPrint("Error updating tasker with files: $e");
      return {"errors": "Failed to update tasker information: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> updateTaskerProfile(
      UserModel user, File profileImage, File documentFile) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$url/update-tasker-with-images/${user.id}"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      request.fields.addAll({
        "first_name": user.firstName,
        "middle_name": user.middleName ?? '',
        "last_name": user.lastName,
        "email": user.email,
        "user_role": user.role,
        "contact": user.contact ?? '',
        "gender": user.gender ?? '',
        "birthdate": user.birthdate ?? '',
      });

      // Add the profile image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "profileImage",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
      );

      // Add the ID image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "documentImage",
          await documentFile.readAsBytes(),
          filename: "document_image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": data["message"] ??
              "User information with images updated successfully!",
          "user": data["user"],
          "profileImage": data["profileImage"],
          "documentImage": data["documentImage"],
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (data['errors'] is String) {
          errorMessage = data['errors'];
        } else if (data['errors'] is List) {
          errorMessage = (data['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {"errors": data["error"] ?? "An unexpected error occurred."};
      }
    } catch (e) {
      debugPrint("Error updating user with images: $e");
      return {
        "errors":
            "An error occurred during updating user information with images: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> setTaskerSchedule(
      TaskerScheduler taskerScheduler) async {
    try {
      final taskerId = await storage.read("user_id");

      return await _postRequest(
          endpoint: "/set-tasker-schedule",
          body: {"tasker_id": taskerId, ...taskerScheduler.toJson()});
    } catch (e, stackTrace) {
      debugPrint("Error setting tasker schedule: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred while setting tasker schedule."};
    }
  }

  static Future<List<TaskerScheduler>> getTaskerSchedule() async {
    try {
      final taskerId = await storage.read("user_id");
      var response = await _getRequest("/get-tasker-schedule/$taskerId");

      if (response.containsKey("tasker_schedule")) {
        List<TaskerScheduler> schedules = [];
        for (var schedule in response["tasker_schedule"]) {
          schedules.add(TaskerScheduler.fromJson(schedule));
        }
        return schedules;
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint("Error getting tasker schedule: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

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
}
