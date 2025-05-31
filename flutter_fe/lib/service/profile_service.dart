import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/config/url_strategy.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'dart:io';

class ProfileService {
  static String url = apiUrl ?? "http://192.168.1.12:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');
  static Future<String?> getUserId() async =>
      storage.read('user_id')?.toString();

  static Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$url$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _getRequest(String endpoint) async {
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

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      debugPrint(response.body.toString());
      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else if (response.statusCode == 400) {
        return {
          "errors": responseBody["errors"] ??
              "Please Check Your Inputs and try again."
        };
      } else {
        debugPrint("API Error Response: $responseBody");
        return {"error": responseBody["error"] ?? "Unknown error"};
      }
    } catch (e) {
      debugPrint("Error parsing response: $e");
      return {"error": "Failed to parse response: $e"};
    }
  }

  static Future<Map<String, dynamic>> _putRequest(
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

  ///
  /// Update Client/Tasker Information
  ///
  static Future<Map<String, dynamic>> updateTasker(TaskerModel tasker,
      UserModel user, List<dynamic> tesdaFiles, File profileImage) async {
    try {
      debugPrint("Updating Tasker information...");
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'Please log in to like jobs',
          'requiresLogin': true
        };
      }

      var request =
          http.MultipartRequest('PUT', Uri.parse('$url/user/tasker/$userId'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Convert tasker.toJson() to Map<String, String>
      final taskerJson = tasker.toJson();
      final taskerFields = <String, String>{};
      taskerJson.forEach((key, value) {
        if (key == 'social_media_links') {
          // Explicitly encode as JSON string
          taskerFields[key] = jsonEncode(value);
          debugPrint("Encoded social_media_links: ${taskerFields[key]}");
        } else {
          taskerFields[key] = value.toString();
        }
      });

      request.fields.addAll({
        ...taskerFields,
        "user_id": (await storage.read("user_id")).toString(),
      });

      // Add profile image
      debugPrint("Adding profile image...");
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
      );

      // Add each TESDA file to the request
      debugPrint("Adding TESDA files...");
      for (var file in tesdaFiles) {
        if (file is String) {
          if (file.startsWith("http")) {
            debugPrint("Skipping remote file: $file");
            continue;
          } else {
            file = File(file);
          }
        }

        if (file is File) {
          String fileName = file.path.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              "documents",
              await file.readAsBytes(),
              filename: fileName,
            ),
          );
        } else {
          debugPrint("Skipping invalid file type: ${file.runtimeType}");
        }
      }

      debugPrint("Request fields: ${request.fields}");
      debugPrint(
          "Request files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}");
      debugPrint("Sending request to: $url/user/tasker/$userId");
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      debugPrint("Response: ${responseBody.body}");
      return _handleResponse(responseBody);
    } catch (e, stackTrace) {
      debugPrint("$e");
      debugPrint(stackTrace.toString());
      return {
        "error":
            "An Error Occurred while Updating Your Profile Information. Please Try Again."
      };
    }
  }

  static Future<Map<String, dynamic>> updateClient(
      ClientModel client, UserModel user, File profileImage) async {
    debugPrint("Updating Client information...");
    final userId = await getUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Please log in to like jobs',
        'requiresLogin': true
      };
    }

    // Create a multipart request for the PUT endpoint
    var request =
        http.MultipartRequest('PUT', Uri.parse('$url/user/client/$userId'));
    request.headers['Authorization'] = 'Bearer $token';

    // Add tasker data as a JSON string in a form field
    request.fields.addAll({
      ...client.toJson().map((key, value) => MapEntry(key, value.toString())),
      "user_id": storage.read("user_id").toString()
    });

    // Add each document file to the 'documents' field
    request.files.addAll([
      http.MultipartFile.fromBytes(
        "image",
        await profileImage.readAsBytes(),
        filename: "profile_image.jpg",
        // Adjust content type if necessary (e.g., image/png)
      ),
    ]);

    try {
      // Send the request and get the response
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      return _handleResponse(responseBody);
    } catch (e) {
      debugPrint("Error uploading files: $e");
      return {"error": "Failed to upload files: $e"};
    }
  }
}
