import 'dart:io';

import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/auth_service.dart';

class TaskerService {
  final storage = GetStorage();
  final String apiUrl = "http://localhost:5000/connect";

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint(response.body);
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint(responseBody.toString());
      return responseBody;
    } else {
      return {"error": responseBody["error"] ?? "Unknown error"};
    }
  }

  Future<Map<String, dynamic>> getTaskerProfile(int taskerId) async {
    try {
      final token = await AuthService.getSessionToken();
      final response = await http.get(
        Uri.parse('$apiUrl/tasker-profile/$taskerId'),
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
        Uri.parse('$apiUrl/document-link/$taskerId'),
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

  Future<Map<String, dynamic>> updateTaskerProfile(
      UserModel user, File profileImage, File documentFile) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-images/${user.id}"),
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
}
