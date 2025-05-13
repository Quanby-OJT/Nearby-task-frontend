// service/api_service.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/conversation.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/tasker_model.dart';
import '../model/client_model.dart';
import 'package:flutter_fe/config/url_strategy.dart';

class ApiService {
  static String url = apiUrl ?? "http://192.168.43.15:5000";
  static final storage = GetStorage();
  static final http.Client _client = http.Client();
  static final Map<String, String> _cookies = {};

  static void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    debugPrint('Raw Cookie: $rawCookie');

    List<String> cookieParts = rawCookie!.split(',');
    for (String part in cookieParts) {
      List<String> keyValue = part.split(';')[0].split('=');
      if (keyValue.length == 2) {
        _cookies[keyValue[0].trim()] = keyValue[1].trim();
      }
    }
    print('Updated Cookies: $_cookies'); // Debugging
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint("Email: $email");
      return await _postRequest(
          endpoint: "/forgot-password", body: {"email": email});
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred during email verification: $error"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String password) async {
    try {
      return await _postRequest(
          endpoint: "/reset-password",
          body: {"email": email, "password": password});
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred during email verification: $error"};
    }
  }

  static Future<Map<String, dynamic>> _postRequest(
      {required String endpoint, required Map<String, dynamic> body}) async {
    final response = await http.post(Uri.parse("$url$endpoint"),
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
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

  // Update tasker profile with PDF file
  static Future<Map<String, dynamic>> updateTaskerWithFile(
      UserModel user, File file) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-file/${user.id}"),
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
        "acc_status": user.accStatus ?? '',
        "birthday": user.birthdate ?? '',
        "contact": user.contact ?? '',
        "gender": user.gender ?? '',
      });

      // Add the ID image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await file.readAsBytes(),
          filename: "file.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body update id image: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information with ID image updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating user information with ID image: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateUser(UserModel user) async {
    try {
      final response = await _client.put(
        Uri.parse("$apiUrl/update-client-user/${user.id}"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          "id": user.id,
          "first_name": user.firstName,
          "middle_name": user.middleName,
          "last_name": user.lastName,
          "email": user.email,
          "user_role": user.role,
          "contact": user.contact,
          "gender": user.gender,
          "birthdate": user.birthdate,
        }),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating user information: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> checkTaskAssignment(
      int taskId, int taskerId) async {
    try {
      String token = await AuthService.getSessionToken();
      final response = await http.get(
        Uri.parse("$apiUrl/check-task-assignment/$taskId/$taskerId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "isAssigned": responseData["isAssigned"] ?? false,
          "message": responseData["message"] ?? "Task assignment status checked"
        };
      } else {
        return {
          "error": responseData["error"] ?? "Failed to check task assignment",
          "isAssigned": false
        };
      }
    } catch (e) {
      debugPrint("Error checking task assignment: $e");
      return {
        "error": "Failed to check task assignment status",
        "isAssigned": false
      };
    }
  }

  static Future<Map<String, dynamic>> assignTask(
      int taskId, int taskerId) async {
    try {
      // First check if task is already assigned
      final checkResult = await checkTaskAssignment(taskId, taskerId);

      if (checkResult["isAssigned"] == true) {
        return {
          "success": false,
          "message": "This task is already assigned to this tasker"
        };
      }

      String token = await AuthService.getSessionToken();
      final response = await http.post(
        Uri.parse("$apiUrl/assign-task"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode({"task_id": taskId, "tasker_id": taskerId}),
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData["message"] ?? "Task assigned successfully"
        };
      } else {
        return {
          "success": false,
          "message": responseData["error"] ?? "Failed to assign task"
        };
      }
    } catch (e) {
      debugPrint("Error assigning task: $e");
      return {
        "success": false,
        "message": "An error occurred while assigning the task"
      };
    }
  }

  // this is for tasker with only pdf
  static Future<Map<String, dynamic>> updateTaskerProfileWithPdf(
      int userId, File file, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getSessionToken();
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-pdf/$userId"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Convert dynamic values to strings
      Map<String, String> stringData = {};
      data.forEach((key, value) {
        stringData[key] = value?.toString() ?? '';
      });

      request.fields.addAll(stringData);

      // Add the profile image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await file.readAsBytes(),
          filename: "file.pdf",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating user information: $e"
      };
    }
  }

  // this is for tasker with files and pdf
  static Future<Map<String, dynamic>> updateTaskerProfileWithImageTobackend(
      int userId, File image, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getSessionToken();
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-image-profile/$userId"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Convert dynamic values to strings
      Map<String, String> stringData = {};
      data.forEach((key, value) {
        stringData[key] = value?.toString() ?? '';
      });

      request.fields.addAll(stringData);

      // Add the ID image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          await image.readAsBytes(),
          filename: "image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating user information: $e"
      };
    }
  }

  // this is for tasker with files and image
  static Future<Map<String, dynamic>> updateTaskerProfileWithFiles(
      int userId, File file, File image, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getSessionToken();
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-file-profile/$userId"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Convert dynamic values to strings
      Map<String, String> stringData = {};
      data.forEach((key, value) {
        stringData[key] = value?.toString() ?? '';
      });

      request.fields.addAll(stringData);

      // Add the profile image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await file.readAsBytes(),
          filename: "file.pdf",
        ),
      );

      // Add the ID image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          await image.readAsBytes(),
          filename: "image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating user information: $e"
      };
    }
  }

  // This is for the tasker updating user information without images and pdf

  static Future<Map<String, dynamic>> updateTaskerProfileNoImages(
      int userId, Map<String, dynamic> data) async {
    try {
      debugPrint('Data: $data');
      debugPrint('User Id from the controller: $userId');
      final token = await AuthService.getSessionToken();
      final response = await _client.put(
        Uri.parse("$apiUrl/update-tasker-profile/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        debugPrint('Response Body po: ${response.body}');
        return json.decode(response.body);
      } else {
        return {"errors": "Failed to update tasker profile"};
      }
    } catch (e) {
      return {"errors": "Exception: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateUserWithProfileImage(
      UserModel user, File profileImage) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-user-with-profile-image/${user.id}"),
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
        "acc_status": user.accStatus ?? '',
        "birthday": user.birthdate ?? '',
        "contact": user.contact ?? '',
        "gender": user.gender ?? '',
      });

      // Add the profile image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "profileImage",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body updated: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information with profile image updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating user information with profile image: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserWithIDImage(
      UserModel user, File idImage) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-user-with-id-image/${user.id}"),
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
        "acc_status": user.accStatus ?? '',
        "birthday": user.birthdate ?? '',
        "contact": user.contact ?? '',
        "gender": user.gender ?? '',
      });

      // Add the ID image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "idImage",
          await idImage.readAsBytes(),
          filename: "id_image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body update id image: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information with ID image updated successfully!",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating user information with ID image: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserWithBothImages(
      UserModel user, File profileImage, File idImage) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-user-with-images/${user.id}"),
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
          "idImage",
          await idImage.readAsBytes(),
          filename: "id_image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "User information with images updated successfully!",
          "user": responseData["user"],
          "profileImage": responseData["profileImage"],
          "idImage": responseData["idImage"],
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      debugPrint("Error updating user with images: $e");
      return {
        "errors":
            "An error occurred during updating user information with images: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      // Create a salt using timestamp
      String salt = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('Request Body: ${user.toJson}'); // Debug log
      final response = await _client.post(
        Uri.parse("$apiUrl/create-new-account"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({...user.toJson(), "salt": salt}),
      );

      // var data = jsonDecode(response.body);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          "message": responseData["message"] ??
              "Registration successful! This email will be used to get your login code.",
          "user": responseData["user"]
        };
      } else if (response.statusCode == 400) {
        if (responseData['errors'] is String) {
          return {"errors": responseData['errors']};
        } else if (responseData['errors'] is List) {
          String errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
          return {"errors": errorMessage};
        }
        return {"errors": "Registration failed. Please try again."};
      } else {
        return {
          "errors": responseData["error"] ??
              "An error occurred during registration. Please try again."
        };
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      return {"errors": "An error occurred while registering your account: $e"};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(
      String token, String email) async {
    try {
      final response = await _client.post(Uri.parse("$apiUrl/verify"),
          headers: _getHeaders(),
          body: json.encode({"token": token, "email": email}));

      debugPrint('Verify Response: ${response.statusCode} - ${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _updateCookies(response);
        return {
          "message": responseData["message"] ?? "Email verified successfully",
          "user_id": responseData["user_id"],
          "session": responseData["session"]
        };
      } else {
        return {
          "error": responseData["error"] ??
              "Email verification failed. Please try again."
        };
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      return {"error": "An error occurred during email verification: $e"};
    }
  }

  // Submit user verification data to the new tasker_verify table
  static Future<Map<String, dynamic>> submitTaskerVerificationWithNewTable(
    int userId,
    Map<String, dynamic> verificationData,
    File? idImage,
    File? selfieImage,
    File? documentFile,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint("ApiService: Submitting tasker verification to new table");
      debugPrint("ApiService: Verification data: $verificationData");

      if (userId == null) {
        return {
          "success": false,
          "error": "User ID is missing from verification data"
        };
      }

      // Create a MultipartRequest for the new verification endpoint
      final String endpoint = "$apiUrl/submit-tasker-verification/$userId";
      debugPrint("ApiService: Using endpoint: $endpoint");

      var request = http.MultipartRequest(
        "POST", // Changed from PUT to POST
        Uri.parse(endpoint),
      );

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Map verification data to match tasker_verify table columns
      request.fields.addAll({
        // Fields for tasker_verify table
        "user_id": userId.toString(),
        "gender": verificationData['gender'] ?? '',
        "phone_number": verificationData['phone'] ?? '',
        "bio": verificationData['bio'] ?? '',
        "social_media_links": verificationData['socialMediaJson'] ?? '{}',

        // Additional fields for user table update
        "first_name": verificationData['firstName'] ?? '',
        "middle_name": verificationData['middleName'] ?? '',
        "last_name": verificationData['lastName'] ?? '',
        "email": verificationData['email'] ?? '',
        "birthdate": verificationData['birthdate'] ?? '',
        "user_role": "tasker",
      });

      // Add ID image if provided
      if (idImage != null) {
        debugPrint("ApiService: Adding ID image to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "idImage",
            await idImage.readAsBytes(),
            filename: "id_image.jpg",
          ),
        );
      }

      // Add selfie image if provided
      if (selfieImage != null) {
        debugPrint("ApiService: Adding selfie image to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "selfieImage",
            await selfieImage.readAsBytes(),
            filename: "selfie_image.jpg",
          ),
        );
      }

      // Add document/certificates file if provided
      if (documentFile != null) {
        debugPrint("ApiService: Adding certificates to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "documents",
            await documentFile.readAsBytes(),
            filename: "certificates.pdf",
          ),
        );
      }

      // Send the request
      debugPrint("ApiService: Sending verification data to server...");
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint("ApiService: Response status: ${response.statusCode}");
      debugPrint("ApiService: Response body: $responseBody");

      // Parse the response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(responseBody);
      } catch (e) {
        debugPrint("ApiService: Error parsing response: $e");
        responseData = {"error": "Invalid response format from server"};
      }

      // Check response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        return {
          "success": true,
          "message": responseData["message"] ??
              "Verification submitted successfully! Your information will be reviewed shortly.",
          "verification": responseData["verification"],
          "idImageUrl": responseData["idImageUrl"],
          "selfieImageUrl": responseData["selfieImageUrl"],
          "documentsUrl": responseData["documentsUrl"]
        };
      } else {
        // Error
        return {
          "success": false,
          "error": responseData["error"] ??
              responseData["errors"] ??
              "Failed to submit verification"
        };
      }
    } catch (e, stackTrace) {
      debugPrint("ApiService: Error submitting verification: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "success": false,
        "error": "An error occurred while submitting verification: $e"
      };
    }
  }

  // Submit user verification data with ID, selfie, and optional document
  // DEPRECATED: Use submitTaskerVerification instead. This method will be removed in a future update.
  static Future<Map<String, dynamic>> submitVerification(
    Map<String, dynamic> verificationData,
    File? idImage,
    File? selfieImage,
    File? documentFile,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint("ApiService: Submitting verification data");
      debugPrint("ApiService: Verification data: $verificationData");

      // Get the user ID from the verification data
      final userId = verificationData['user_id'];
      if (userId == null) {
        return {
          "success": false,
          "error": "User ID is missing from verification data"
        };
      }

      // Create a MultipartRequest for the update-tasker endpoint
      // Fix the URL to avoid duplicate "connect" segment
      final String endpoint = "$apiUrl/update-tasker-profile/$userId";
      debugPrint("ApiService: Using endpoint: $endpoint");

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse(endpoint),
      );

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Format the data according to the backend's expected structure
      Map<String, dynamic> taskerData = {
        "tasker_id": userId,
        "bio": verificationData['bio'] ?? "",
        "skills": verificationData['skills'] ?? "",
        "availability": true,
        "wage_per_hour": verificationData['wage'] ?? 0,
        "social_media_links": verificationData['social_media_json'] ?? "{}",
        "pay_period": verificationData['pay_period'] ?? "Hourly",
        "specialization_id": verificationData['specialization_id'] ?? 1,
        "specialization": verificationData['specialization'] ?? ""
      };

      // Convert all values to strings for the multipart request
      Map<String, String> formFields = {};
      taskerData.forEach((key, value) {
        if (value is Map) {
          formFields[key] = jsonEncode(value);
        } else {
          formFields[key] = value.toString();
        }
      });

      // Add the fields to the request
      request.fields.addAll(formFields);

      // Add user profile fields
      request.fields.addAll({
        "first_name": verificationData['first_name'] ?? '',
        "middle_name": verificationData['middle_name'] ?? '',
        "last_name": verificationData['last_name'] ?? '',
        "email": verificationData['email'] ?? '',
        "contact": verificationData['phone'] ?? '',
        "gender": verificationData['gender'] ?? '',
        "birthdate": verificationData['birthdate'] ?? '',
        "user_role": "tasker"
      });

      // Add ID image if provided
      if (idImage != null) {
        debugPrint("ApiService: Adding ID image to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "id_image",
            await idImage.readAsBytes(),
            filename: "id_image.jpg",
          ),
        );
      }

      // Add selfie image if provided
      if (selfieImage != null) {
        debugPrint("ApiService: Adding selfie image to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "profile_image",
            await selfieImage.readAsBytes(),
            filename: "profile_image.jpg",
          ),
        );
      }

      // Add document file if provided
      if (documentFile != null) {
        debugPrint("ApiService: Adding document to request");
        request.files.add(
          http.MultipartFile.fromBytes(
            "document",
            await documentFile.readAsBytes(),
            filename: "document.pdf",
          ),
        );
      }

      // Send the request
      debugPrint("ApiService: Sending verification data to server...");
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint("ApiService: Response status: ${response.statusCode}");
      debugPrint("ApiService: Response body: $responseBody");

      // Parse the response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(responseBody);
      } catch (e) {
        debugPrint("ApiService: Error parsing response: $e");
        responseData = {"error": "Invalid response format from server"};
      }

      // Check response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        return {
          "success": true,
          "message": responseData["message"] ??
              "Verification submitted successfully! Your information will be reviewed shortly."
        };
      } else {
        // Error
        return {
          "success": false,
          "error": responseData["error"] ??
              responseData["errors"] ??
              "Failed to submit verification"
        };
      }
    } catch (e, stackTrace) {
      debugPrint("ApiService: Error submitting verification: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "success": false,
        "error": "An error occurred while submitting verification: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> createTasker(
      TaskerModel tasker, File tesdaFile, File profileImage) async {
    try {
      //Code to store uploaded files to database, and retrieve its url link.

      String token = await AuthService.getSessionToken();
      debugPrint("Sending data: ${tasker.toJson()}");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$apiUrl/create-new-tasker"),
      );
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      request.fields.addAll({
        ...tasker.toJson().map((key, value) => MapEntry(key, value.toString())),
        "user_id": storage.read("user_id").toString(),
      });

      request.files.addAll([
        http.MultipartFile.fromBytes(
          "document",
          await tesdaFile.readAsBytes(),
          filename: "document.pdf",
        ),
        http.MultipartFile.fromBytes(
          "image",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
      ]);

      var response = await request.send();

      debugPrint("Status Code: ${response.statusCode}");
      var body = await response.stream.bytesToString();
      var responseData = jsonDecode(body);
      debugPrint("Response Data: $responseData");

      if (response.statusCode == 201) {
        return {
          "message": responseData["message"] ??
              "Profile Created Successfully. Please Wait for Our Team to Verify Your Account"
        };
      } else if (response.statusCode == 400) {
        return {
          "error":
              responseData["errors"] ?? "Please Check Your inputs and try again"
        };
      } else {
        return {
          "error": responseData["error"] ??
              "Something went wrong when creating your profile. Please try again."
        };
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "Something went wrong when creating your profile. Please try again."
      };
    }
  }

  static Future<Map<String, dynamic>> fetchAuthenticatedUser(int userId) async {
    try {
      final String token = await AuthService.getSessionToken();

      // Check if token is empty and handle accordingly
      if (token.isEmpty) {
        return {"error": "No valid session token. Please log in again."};
      }

      final response = await http.get(Uri.parse("$apiUrl/getUserData/$userId"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          });

      debugPrint("Retreived Data from: ${response.body}");
      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        UserModel user =
            UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
        if (responseData['user']['user_role'].toLowerCase() == "client") {
          debugPrint(
              "User is a client and has client data: ${responseData['client']}");
          ClientModel client = ClientModel.fromJson(
              responseData['client'] as Map<String, dynamic>);
          return {"user": user, "client": client};
        } else if (responseData['user']['user_role'].toLowerCase() ==
            "tasker") {
          debugPrint(
              "User is a tasker and has tasker data: ${responseData['tasker']}");
          TaskerModel tasker = TaskerModel.fromJson(
              responseData['tasker'] as Map<String, dynamic>);

          debugPrint("User is a tasker and has tasker data: $tasker");

          return {"user": user, "tasker": tasker};
        } else {
          return {
            "error": responseData['error'] ??
                "An Error Occured while retrieving data"
          };
        }
      } else {
        return {"error": responseData['error'] ?? "Failed to fetch user data"};
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "An error occurred while retrieving your information. Please try again."
      };
    }
  }

  static Future<Map<String, dynamic>> authUser(
      String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/login-auth"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      //_updateCookies(response);

      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"user_id": responseData['user_id']};
      } else if (response.statusCode == 400 &&
          responseData.containsKey('errors')) {
        List<dynamic> errors = responseData['errors'];
        String errorMessage = errors.map((e) => e['msg']).join('\n');
        return {"validation_error": errorMessage};
      } else {
        return {"error": responseData['error'] ?? 'Authentication Failed'};
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> regenerateOTP(int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/reset"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId,
        }),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"message": responseData['message']};
      } else if (response.statusCode == 400 &&
          responseData.containsKey('errors')) {
        // Handle validation errors from backend
        List<dynamic> errors = responseData['errors'];
        String validationMessage = errors.map((e) => e['message']).join("\n");
        return {"validation_error": validationMessage};
      } else {
        return {"error": responseData['error'] ?? "OTP Generation Failed"};
      }
    } catch (e) {
      debugPrint('Error: $e');
      return {"error": "An error occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> authOTP(int userId, String otp) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/otp-auth"),
        headers: _getHeaders(), // 🔥 Send stored cookies
        body: json.encode({
          "user_id": userId,
          "otp": otp,
        }),
      );

      //debugPrint('Sent Headers: ${_getHeaders()}'); // Debugging
      //_updateCookies(response); // 🔥 Store session cookies

      var responseData = json.decode(response.body);
      debugPrint('Decoded Data Type: ${responseData.runtimeType}');
      debugPrint('Response Data: $responseData'); // Debugging

      if (response.statusCode == 200) {
        // Extract session from cookies if not in response data
        String? sessionFromCookies = _cookies['session'];
        debugPrint('Session from cookies: $sessionFromCookies');

        return {
          "user_id": responseData['user_id'],
          "role": responseData['user_role'],
          "session": responseData['session'] ?? sessionFromCookies ?? ""
        };
      } else if (response.statusCode == 400 &&
          responseData.containsKey('errors')) {
        List<dynamic> errors = responseData['errors'];
        String validationMessage = errors.map((e) => e['msg']).join("\n");
        debugPrint(validationMessage);
        return {"validation_error": validationMessage};
      } else {
        return {
          "error": responseData['error'] ??
              "OTP Authentication Failed. Please Try again."
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "OTP Authentication Failed. Please Try again. If the Problem Persists, Contact Us."
      };
    }
  }

  static Future<Map<String, dynamic>> logout(int userId, String session) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $session",
          "Access-Control-Allow-Credentials": "true"
        },
        body: json.encode({"user_id": userId, "session": session}),
      );

      debugPrint('Logout Status Code: ${response.statusCode}');
      debugPrint('Logout Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _cookies.remove("session"); // Remove only the session cookie
        storage.erase();
        return {"message": "Logged out successfully"};
      } else {
        var responseData = json.decode(response.body);
        return {"error": responseData['error'] ?? "Failed to logout"};
      }
    } catch (e) {
      debugPrint('Logout Error: $e');
      return {"error": "Connection error during logout"};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
      Conversation conversation) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.post(Uri.parse("$apiUrl/send-message"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          },
          body: jsonEncode(conversation.toJson()));

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ?? "Successfully Sent the Message"
        };
      } else if (response.statusCode == 400) {
        return {
          "error":
              responseData["errors"] ?? "Please Check Your inputs and try again"
        };
      } else {
        // Handle unexpected response statuses
        return {
          "error":
              "Unexpected error occurred. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {
        "error": "An Error Occured while Sending a Message. Please Try Again"
      };
    }
  }

  static Future<Map<String, dynamic>> getMessages(int taskTakenId) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.get(
        Uri.parse("$apiUrl/messages/$taskTakenId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("All Messages Data: ${response.body}");

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null && responseData['data'] is List) {
          return {"messages": responseData['data']}; // Return the list directly
        } else {
          return {}; // No messages found
        }
      } else {
        return {
          "error": responseData['error'] ?? "Failed to retrieve messages"
        };
      }
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {
        "error":
            "An error occurred while retrieving your conversation. Please try again."
      };
    }
  }

  static Future<Map<String, dynamic>> updateTasker(TaskerModel tasker) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.put(
        Uri.parse("$apiUrl/update-tasker/${tasker.id}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode(tasker.toJson()),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "Tasker information updated successfully!",
          "tasker": responseData["tasker"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating tasker information: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateTaskerWithProfileImage(
      TaskerModel tasker, File profileImage) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-profile-image/${tasker.id}"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add all tasker fields
      request.fields.addAll({
        ...tasker.toJson().map((key, value) => MapEntry(key, value.toString())),
      });

      // Add the profile image to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "Tasker information with profile image updated successfully!",
          "tasker": responseData["tasker"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating tasker information with profile image: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateTaskerWithDocument(
      TaskerModel tasker, File documentFile) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-document/${tasker.id}"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add all tasker fields
      request.fields.addAll({
        ...tasker.toJson().map((key, value) => MapEntry(key, value.toString())),
      });

      // Add the document file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          "document",
          await documentFile.readAsBytes(),
          filename: "document.pdf",
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "Tasker information with document updated successfully!",
          "tasker": responseData["tasker"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating tasker information with document: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> updateTaskerWithBothFiles(
      TaskerModel tasker, File profileImage, File documentFile) async {
    try {
      String token = await AuthService.getSessionToken();

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$apiUrl/update-tasker-with-files/${tasker.id}"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add all tasker fields
      request.fields.addAll({
        ...tasker.toJson().map((key, value) => MapEntry(key, value.toString())),
      });

      // Add both files to the request
      request.files.addAll([
        http.MultipartFile.fromBytes(
          "image",
          await profileImage.readAsBytes(),
          filename: "profile_image.jpg",
        ),
        http.MultipartFile.fromBytes(
          "document",
          await documentFile.readAsBytes(),
          filename: "document.pdf",
        ),
      ]);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ??
              "Tasker information with files updated successfully!",
          "tasker": responseData["tasker"]
        };
      } else if (response.statusCode == 400) {
        String errorMessage = "";
        if (responseData['errors'] is String) {
          errorMessage = responseData['errors'];
        } else if (responseData['errors'] is List) {
          errorMessage = (responseData['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
        }
        return {
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred."
        };
      }
    } catch (e) {
      return {
        "errors":
            "An error occurred during updating tasker information with files: $e"
      };
    }
  }

  static Map<String, String> _getHeaders() {
    String cookieHeader =
        _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_cookies.isNotEmpty) "Cookie": cookieHeader,
    };
  }

  // Get tasker verification status
  static Future<Map<String, dynamic>> getTaskerVerificationStatus(
      int userId) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.get(
        Uri.parse("$apiUrl/tasker-verification-status/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint(
          "ApiService: Verification status response status: ${response.statusCode}");
      debugPrint(
          "ApiService: Verification status response body: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "exists": responseData["exists"] ?? false,
          "verification": responseData["verification"],
          "message": responseData["message"],
        };
      } else {
        return {
          "success": false,
          "exists": false,
          "error": responseData["error"] ?? "An unexpected error occurred",
        };
      }
    } catch (e) {
      debugPrint("ApiService: Error checking verification status: $e");
      return {
        "success": false,
        "exists": false,
        "error": "Error checking verification status: $e",
      };
    }
  }
}
