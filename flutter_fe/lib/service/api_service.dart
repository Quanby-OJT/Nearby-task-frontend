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
import 'package:flutter_fe/config/url_strategy.dart';

class ApiService {
  static String url = apiUrl ?? "https://localhost:3000";
  static final storage = GetStorage();
  static final http.Client _client = http.Client();
  static final Map<String, String> _cookies = {};

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
          "Content-Type": "application/json",
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

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint("Email: $email");
      return await _postRequest(
        endpoint: "/forgot-password",
        body: {"email": email},
      );
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred during email verification: $error"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String password,
  ) async {
    try {
      return await _postRequest(
        endpoint: "/reset-password",
        body: {"email": email, "password": password},
      );
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred during email verification: $error"};
    }
  }

  static Future<Map<String, dynamic>> _postRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      Uri.parse("$url$endpoint"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        debugPrint("API Error Response: $responseBody");
        return {"error": responseBody ?? "Unknown error"};
      }
    } catch (e, stackTrace) {
      debugPrint("Error parsing response: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "Failed to parse response. Please try again."};
    }
  }

  static Future<Map<String, dynamic>> checkTaskAssignment(
    int taskId,
    int taskerId,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      final response = await http.get(
        Uri.parse("$apiUrl/check-task-assignment/$taskId/$taskerId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "isAssigned": responseData["isAssigned"] ?? false,
          "message":
              responseData["message"] ?? "Task assignment status checked",
        };
      } else {
        return {
          "error": responseData["error"] ?? "Failed to check task assignment",
          "isAssigned": false,
        };
      }
    } catch (e) {
      debugPrint("Error checking task assignment: $e");
      return {
        "error": "Failed to check task assignment status",
        "isAssigned": false,
      };
    }
  }

  static Future<Map<String, dynamic>> assignTask(
    int taskId,
    int taskerId,
  ) async {
    try {
      // First check if task is already assigned
      final checkResult = await checkTaskAssignment(taskId, taskerId);

      if (checkResult["isAssigned"] == true) {
        return {
          "success": false,
          "message": "This task is already assigned to this tasker",
        };
      }

      // String token = await AuthService.getSessionToken();
      // final response = await http.post(
      //   Uri.parse("$apiUrl/assign-task"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json"
      //   },
      //   body: json.encode({"task_id": taskId, "tasker_id": taskerId}),
      // );
      //
      // var responseData = jsonDecode(response.body);
      //
      // if (response.statusCode == 200) {
      //   return {
      //     "success": true,
      //     "message": responseData["message"] ?? "Task assigned successfully"
      //   };

      // } else {
      //   return {
      //     "success": false,
      //     "message": responseData["error"] ?? "Failed to assign task"
      //   };
      // }

      return await _postRequest(
        endpoint: '/assign-task',
        body: {"task_id": taskId, "tasker_id": taskerId},
      );
    } catch (e) {
      debugPrint("Error assigning task: $e");
      return {
        "success": false,
        "message": "An error occurred while assigning the task",
      };
    }
  }

  // // this is for tasker with only pdf
  // static Future<Map<String, dynamic>> updateTaskerProfileWithPdf(int userId, File file, Map<String, dynamic> data) async {
  //   try {
  //     final token = await AuthService.getSessionToken();
  //     final request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-tasker-with-pdf/$userId"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     // Convert dynamic values to strings
  //     Map<String, String> stringData = {};
  //     data.forEach((key, value) {
  //       stringData[key] = value?.toString() ?? '';
  //     });
  //
  //     request.fields.addAll(stringData);
  //
  //     // Add the profile image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "file",
  //         await file.readAsBytes(),
  //         filename: "file.pdf",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information updated successfully!",
  //         "user": responseData["user"]
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "errors": "An error occurred during updating user information: $e"
  //     };
  //   }
  // }
  //
  // // this is for tasker with files and pdf
  // static Future<Map<String, dynamic>> updateTaskerProfileWithImageTobackend(int userId, File image, Map<String, dynamic> data) async {
  //   try {
  //     final token = await AuthService.getSessionToken();
  //     final request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-tasker-with-image-profile/$userId"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     // Convert dynamic values to strings
  //     Map<String, String> stringData = {};
  //     data.forEach((key, value) {
  //       stringData[key] = value?.toString() ?? '';
  //     });
  //
  //     request.fields.addAll(stringData);
  //
  //     // Add the ID image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "image",
  //         await image.readAsBytes(),
  //         filename: "image.jpg",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information updated successfully!",
  //         "user": responseData["user"]
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "errors": "An error occurred during updating user information: $e"
  //     };
  //   }
  // }
  //
  // // this is for tasker with files and image
  // static Future<Map<String, dynamic>> updateTaskerProfileWithFiles(int userId, File file, File image, Map<String, dynamic> data) async {
  //   try {
  //     final token = await AuthService.getSessionToken();
  //     final request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-tasker-with-file-profile/$userId"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     // Convert dynamic values to strings
  //     Map<String, String> stringData = {};
  //     data.forEach((key, value) {
  //       stringData[key] = value?.toString() ?? '';
  //     });
  //
  //     request.fields.addAll(stringData);
  //
  //     // Add the profile image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "file",
  //         await file.readAsBytes(),
  //         filename: "file.pdf",
  //       ),
  //     );
  //
  //     // Add the ID image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "image",
  //         await image.readAsBytes(),
  //         filename: "image.jpg",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information updated successfully!",
  //         "user": responseData["user"]
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "errors": "An error occurred during updating user information: $e"
  //     };
  //   }
  // }
  //
  // // This is for the tasker updating user information without images and pdf
  //
  // static Future<Map<String, dynamic>> updateTaskerProfileNoImages(int userId, Map<String, dynamic> data) async {
  //   try {
  //     debugPrint('Data: $data');
  //     debugPrint('User Id from the controller: $userId');
  //     final token = await AuthService.getSessionToken();
  //     final response = await _client.put(
  //       Uri.parse("$apiUrl/update-tasker-profile/$userId"),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Accept": "application/json",
  //         "Authorization": "Bearer $token",
  //       },
  //       body: json.encode(data),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       debugPrint('Response Body po: ${response.body}');
  //       return json.decode(response.body);
  //     } else {
  //       return {"errors": "Failed to update tasker profile"};
  //     }
  //   } catch (e) {
  //     return {"errors": "Exception: $e"};
  //   }
  // }
  //
  // static Future<Map<String, dynamic>> updateUserWithProfileImage(UserModel user, File profileImage) async {
  //   try {
  //     String token = await AuthService.getSessionToken();
  //
  //     var request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-user-with-profile-image/${user.id}"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     request.fields.addAll({
  //       "first_name": user.firstName,
  //       "middle_name": user.middleName ?? '',
  //       "last_name": user.lastName,
  //       "email": user.email,
  //       "user_role": user.role,
  //       "acc_status": user.accStatus ?? '',
  //       "birthday": user.birthdate ?? '',
  //       "contact": user.contact ?? '',
  //       "gender": user.gender ?? '',
  //     });
  //
  //     // Add the profile image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "profileImage",
  //         await profileImage.readAsBytes(),
  //         filename: "profile_image.jpg",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body updated: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information with profile image updated successfully!",
  //         "user": responseData["user"]
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "errors":
  //           "An error occurred during updating user information with profile image: $e"
  //     };
  //   }
  // }
  //
  // static Future<Map<String, dynamic>> updateUserWithIDImage(UserModel user, File idImage) async {
  //   try {
  //     String token = await AuthService.getSessionToken();
  //
  //     var request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-user-with-id-image/${user.id}"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     request.fields.addAll({
  //       "first_name": user.firstName,
  //       "middle_name": user.middleName ?? '',
  //       "last_name": user.lastName,
  //       "email": user.email,
  //       "user_role": user.role,
  //       "acc_status": user.accStatus ?? '',
  //       "birthday": user.birthdate ?? '',
  //       "contact": user.contact ?? '',
  //       "gender": user.gender ?? '',
  //     });
  //
  //     // Add the ID image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "idImage",
  //         await idImage.readAsBytes(),
  //         filename: "id_image.jpg",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body update id image: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information with ID image updated successfully!",
  //         "user": responseData["user"]
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "errors":
  //           "An error occurred during updating user information with ID image: $e"
  //     };
  //   }
  // }
  //
  // static Future<Map<String, dynamic>> updateUserWithBothImages(UserModel user, File profileImage, File idImage) async {
  //   try {
  //     String token = await AuthService.getSessionToken();
  //
  //     var request = http.MultipartRequest(
  //       "PUT",
  //       Uri.parse("$apiUrl/update-user-with-images/${user.id}"),
  //     );
  //
  //     request.headers.addAll({
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "multipart/form-data",
  //     });
  //
  //     request.fields.addAll({
  //       "first_name": user.firstName,
  //       "middle_name": user.middleName ?? '',
  //       "last_name": user.lastName,
  //       "email": user.email,
  //       "user_role": user.role,
  //       "contact": user.contact ?? '',
  //       "gender": user.gender ?? '',
  //       "birthdate": user.birthdate ?? '',
  //     });
  //
  //     // Add the profile image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "profileImage",
  //         await profileImage.readAsBytes(),
  //         filename: "profile_image.jpg",
  //       ),
  //     );
  //
  //     // Add the ID image to the request
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         "idImage",
  //         await idImage.readAsBytes(),
  //         filename: "id_image.jpg",
  //       ),
  //     );
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     debugPrint('Response Status: ${response.statusCode}');
  //     debugPrint('Response Body: $responseBody');
  //
  //     final responseData = jsonDecode(responseBody);
  //
  //     if (response.statusCode == 200) {
  //       return {
  //         "message": responseData["message"] ??
  //             "User information with images updated successfully!",
  //         "user": responseData["user"],
  //         "profileImage": responseData["profileImage"],
  //         "idImage": responseData["idImage"],
  //       };
  //     } else if (response.statusCode == 400) {
  //       String errorMessage = "";
  //       if (responseData['errors'] is String) {
  //         errorMessage = responseData['errors'];
  //       } else if (responseData['errors'] is List) {
  //         errorMessage = (responseData['errors'] as List)
  //             .map((e) => e['msg'] ?? e.toString())
  //             .join('\n');
  //       }
  //       return {
  //         "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed."
  //       };
  //     } else {
  //       return {
  //         "errors": responseData["error"] ?? "An unexpected error occurred."
  //       };
  //     }
  //   } catch (e) {
  //     debugPrint("Error updating user with images: $e");
  //     return {
  //       "errors":
  //           "An error occurred during updating user information with images: $e"
  //     };
  //   }
  // }

  static Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      // Create a salt using timestamp
      String salt = DateTime.now().millisecondsSinceEpoch.toString();

      // Create the request body
      Map<String, dynamic> requestBody = {...user.toJson(), "salt": salt};

      // Debug logs
      debugPrint('Register User - Request Body: ${json.encode(requestBody)}');
      debugPrint(
        'Register User - Password included: ${requestBody.containsKey("password")}',
      );

      final response = await _client.post(
        Uri.parse("$apiUrl/create-new-account"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(requestBody),
      );

      debugPrint('Register User - Response Status: ${response.statusCode}');
      debugPrint('Register User - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          "message": responseData["message"] ??
              "Registration successful! This email will be used to get your login code.",
          "user": responseData["user"],
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
              "An error occurred during registration. Please try again.",
        };
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      return {"errors": "An error occurred while registering your account: $e"};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(
    String token,
    String email,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/verify"),
        headers: _getHeaders(),
        body: json.encode({"token": token, "email": email}),
      );

      debugPrint('Verify Response: ${response.statusCode} - ${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // _updateCookies(response);
        return {
          "message": "Email verified successfully",
          "user_id": responseData["user_id"],
          "session": responseData["session"],
        };
      } else {
        return {
          "error": responseData["error"] ??
              "Email verification failed. Please try again.",
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Verification Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {"error": "An error occurred during email verification. Please Try Again. If the Problem Persists, please contact us."};
    }
  }

  // Submit user verification data to the user_verify table (unified for both Tasker and Client)
  static Future<Map<String, dynamic>> submitUserVerification(
    int userId,
    Map<String, dynamic> verificationData,
    File? idImage,
    File? selfieImage,
    File? documentFile,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint(
        "ApiService: Submitting user verification to user_verify table",
      );
      debugPrint("ApiService: Verification data: $verificationData");

      // Check if this is an update to existing verification
      final bool isUpdate = verificationData['status'] != null &&
          verificationData['status'] != 'pending';

      final String endpoint = "$apiUrl/submit-user-verification/$userId";
      debugPrint("ApiService: Using endpoint: $endpoint");
      debugPrint("ApiService: Is update: $isUpdate");

      var request = http.MultipartRequest(
        "POST", // Using POST for both new submissions and updates
        Uri.parse(endpoint),
      );

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Map verification data to match user_verify table columns
      request.fields.addAll({
        // Fields for user_verify table
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
        "user_role":
            verificationData['userRole'] ?? 'tasker', // Support both roles
        // Add a flag to indicate if this is an update
        "is_update": isUpdate.toString(),
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
        debugPrint("ApiService: Adding documents to request");
        request.files.add(
          await http.MultipartFile.fromPath("documents", documentFile.path),
        );
      }

      // Send the request
      debugPrint("ApiService: Sending user verification data to server...");
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
        debugPrint("ApiService: Verification submission successful");
        return {
          "success": true,
          "message": responseData["message"] ??
              "Verification submitted successfully! Your information will be reviewed shortly.",
        };
      } else {
        // Error
        debugPrint(
          "ApiService: Verification submission failed with status: ${response.statusCode}",
        );
        debugPrint("ApiService: Error response: $responseData");
        return {
          "success": false,
          "error": responseData["error"] ??
              responseData["errors"] ??
              "Failed to submit verification. Status: ${response.statusCode}",
        };
      }
    } catch (e, stackTrace) {
      debugPrint("ApiService: Error submitting user verification: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "success": false,
        "error": "An error occurred while submitting verification: $e",
      };
    }
  }

  // Submit client verification data to the client table
  static Future<Map<String, dynamic>> submitClientVerification(
    int userId,
    Map<String, dynamic> verificationData,
    File? idImage,
    File? selfieImage,
    File? documentFile,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint("ApiService: Submitting client verification");
      debugPrint("ApiService: Verification data: $verificationData");

      final String endpoint = "$apiUrl/submit-client-verification/$userId";
      var request = http.MultipartRequest("POST", Uri.parse(endpoint));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add verification data fields
      request.fields.addAll({
        "user_id": userId.toString(),
        "firstName": verificationData['firstName'] ?? '',
        "middleName": verificationData['middleName'] ?? '',
        "lastName": verificationData['lastName'] ?? '',
        "email": verificationData['email'] ?? '',
        "phone": verificationData['phone'] ?? '',
        "gender": verificationData['gender'] ?? '',
        "birthdate": verificationData['birthdate'] ?? '',
        "profileImageUrl": verificationData['profileImageUrl'] ??
            '', // Include profile image URL
      });

      // Add files
      if (idImage != null && await idImage.exists()) {
        debugPrint("ApiService: Adding ID image");
        request.files.add(
          await http.MultipartFile.fromPath('idImage', idImage.path),
        );
      }

      if (selfieImage != null && await selfieImage.exists()) {
        debugPrint("ApiService: Adding selfie image");
        request.files.add(
          await http.MultipartFile.fromPath('selfieImage', selfieImage.path),
        );
      }

      if (documentFile != null && await documentFile.exists()) {
        debugPrint("ApiService: Adding documents");
        request.files.add(
          await http.MultipartFile.fromPath('documents', documentFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      debugPrint("ApiService: Client verification response: $responseData");

      if (response.statusCode == 200 || response.statusCode == 207) {
        return {
          "success": responseData["success"] ?? false,
          "message": responseData["message"] ?? "Client verification submitted",
          "data": responseData["data"],
          "failedTables": responseData["failedTables"],
          "uploadErrors": responseData["uploadErrors"],
        };
      } else {
        return {
          "success": false,
          "error":
              responseData["error"] ?? "Failed to submit client verification",
        };
      }
    } catch (e, stackTrace) {
      debugPrint("ApiService: Error submitting client verification: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"success": false, "error": "An error occurred: $e"};
    }
  }

  // Submit tasker verification data to the tasker table
  static Future<Map<String, dynamic>> submitTaskerVerificationNew(
    int userId,
    Map<String, dynamic> verificationData,
    File? idImage,
    File? selfieImage,
    File? documentFile,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint("ApiService: Submitting tasker verification to tasker table");
      debugPrint("ApiService: Verification data: $verificationData");

      final String endpoint = "$apiUrl/submit-tasker-verification-new/$userId";

      var request = http.MultipartRequest("POST", Uri.parse(endpoint));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add verification data fields
      request.fields.addAll({
        "user_id": userId.toString(),
        "firstName": verificationData['firstName'] ?? '',
        "middleName": verificationData['middleName'] ?? '',
        "lastName": verificationData['lastName'] ?? '',
        "email": verificationData['email'] ?? '',
        "phone": verificationData['phone'] ?? '',
        "gender": verificationData['gender'] ?? '',
        "birthdate": verificationData['birthdate'] ?? '',
        "profileImageUrl": verificationData['profileImageUrl'] ??
            '', // Include profile image URL
      });

      // Add files only if they exist and are readable
      if (idImage != null && await idImage.exists()) {
        debugPrint("ApiService: Adding ID image to request");
        request.files.add(
          await http.MultipartFile.fromPath('idImage', idImage.path),
        );
      }

      if (selfieImage != null && await selfieImage.exists()) {
        debugPrint("ApiService: Adding selfie image to request");
        request.files.add(
          await http.MultipartFile.fromPath('selfieImage', selfieImage.path),
        );
      }

      if (documentFile != null && await documentFile.exists()) {
        debugPrint("ApiService: Adding documents to request");
        request.files.add(
          await http.MultipartFile.fromPath('documents', documentFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      debugPrint("ApiService: Tasker verification response: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": responseData["message"] ??
              "Tasker verification submitted successfully!",
        };
      } else {
        return {
          "success": false,
          "error":
              responseData["error"] ?? "Failed to submit tasker verification",
        };
      }
    } catch (e, stackTrace) {
      debugPrint("ApiService: Error submitting tasker verification: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "success": false,
        "error": "An error occurred while submitting tasker verification: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> createTasker(
    TaskerModel tasker,
    File tesdaFile,
    File profileImage,
  ) async {
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
              "Profile Created Successfully. Please Wait for Our Team to Verify Your Account",
        };
      } else if (response.statusCode == 400) {
        return {
          "error": responseData["errors"] ??
              "Please Check Your inputs and try again",
        };
      } else {
        return {
          "error": responseData["error"] ??
              "Something went wrong when creating your profile. Please try again.",
        };
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "Something went wrong when creating your profile. Please try again.",
      };
    }
  }

  Future<Map<String, dynamic>> fetchAuthenticatedUser(int userId) async {
    try {
      String role = storage.read('role');

      if (role == "Tasker") {
        return await _getRequest("/get-tasker-profile/$userId");
      } else if (role == "Client") {
        return await _getRequest("/get-client-info/$userId");
      }

      return {"error": "Invalid role"};
    } catch (e, stackTrace) {
      debugPrint("Exception in fetchAuthenticatedUser: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "An error occurred while retrieving your information. Please try again.",
      };
    }
  }

  Future<Map<String, dynamic>> fetchAuthenticatedUserClient(int userId) async {
    try {
      return await _getRequest("/get-client-info/$userId");
    } catch (e, stackTrace) {
      debugPrint("Exception in fetchAuthenticatedUser: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "An error occurred while retrieving your information. Please try again.",
      };
    }
  }

  static Future<Map<String, dynamic>> authUser(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/login-auth"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"user_id": responseData['user_id']};
      } else if (response.statusCode == 429) {
        // Handle throttling
        return {
          "error": responseData['error'],
          "remainingTime": responseData['remainingTime'],
          "isThrottled": true,
        };
      } else if (response.statusCode == 400 &&
          responseData.containsKey('errors')) {
        List<dynamic> errors = responseData['errors'];
        String errorMessage = errors.map((e) => e['msg']).join('\n');
        return {"validation_error": errorMessage};
      } else {
        String message = responseData['error'] ?? 'Authentication Failed';
        if (responseData.containsKey('attemptsLeft')) {
          message += '\nAttempts left: ${responseData['attemptsLeft']}';
        }
        return {"error": message};
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
        body: json.encode({"user_id": userId}),
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
        body: json.encode({"user_id": userId, "otp": otp}),
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
          "session": responseData['session'] ?? sessionFromCookies ?? "",
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
              "OTP Authentication Failed. Please Try again.",
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "OTP Authentication Failed. Please Try again. If the Problem Persists, Contact Us.",
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
          "Access-Control-Allow-Credentials": "true",
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
    Conversation conversation,
  ) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.post(
        Uri.parse("$apiUrl/send-message"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(conversation.toJson()),
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "message": responseData["message"] ?? "Successfully Sent the Message",
        };
      } else if (response.statusCode == 400) {
        return {
          "error": responseData["errors"] ??
              "Please Check Your inputs and try again",
        };
      } else {
        // Handle unexpected response statuses
        return {
          "error":
              "Unexpected error occurred. Status code: ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {
        "error": "An Error Occured while Sending a Message. Please Try Again",
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
          "error": responseData['error'] ?? "Failed to retrieve messages",
        };
      }
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {
        "error":
            "An error occurred while retrieving your conversation. Please try again.",
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
          "Content-Type": "application/json",
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
          "tasker": responseData["tasker"],
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
          "errors": errorMessage.isNotEmpty ? errorMessage : "Update failed.",
        };
      } else {
        return {
          "errors": responseData["error"] ?? "An unexpected error occurred.",
        };
      }
    } catch (e) {
      return {
        "errors": "An error occurred during updating tasker information: $e",
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

  // Get user verification status (unified for both Tasker and Client)
  static Future<Map<String, dynamic>> getUserVerificationStatus(
    int userId,
  ) async {
    try {
      String token = await AuthService.getSessionToken();

      final response = await http.get(
        Uri.parse("$apiUrl/user-verification-status/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint(
        "ApiService: User verification status response status for tasker: ${response.statusCode}",
      );
      debugPrint(
        "ApiService: User verification status response body for tasker: ${response.body}",
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "exists": responseData["exists"] ?? false,
          "verification": responseData["verification"],
          "user": responseData["user"],
          "idImage": responseData["idImage"],
          "faceImage": responseData["faceImage"],
          "userDocuments": responseData["userDocuments"],
          "clientDocuments": responseData["clientDocuments"],
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
      debugPrint("ApiService: Error checking user verification status: $e");
      return {
        "success": false,
        "exists": false,
        "error": "Error checking verification status: $e",
      };
    }
  }

  // Get tasker verification status (kept for backward compatibility)
  static Future<Map<String, dynamic>> getTaskerVerificationStatus(
    int userId,
  ) async {
    // Use the unified getUserVerificationStatus method
    return await getUserVerificationStatus(userId);
  }

  // Upload profile image to tasker_images table
  static Future<Map<String, dynamic>> uploadTaskerProfileImage(
    int userId,
    File profileImage,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint("ApiService: Uploading profile image for user: $userId");

      final String endpoint = "$apiUrl/upload-tasker-profile-image/$userId";

      var request = http.MultipartRequest("POST", Uri.parse(endpoint));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add user ID
      request.fields['user_id'] = userId.toString();

      // Add profile image file
      if (await profileImage.exists()) {
        debugPrint("ApiService: Adding profile image to request");
        request.files.add(
          await http.MultipartFile.fromPath('tasker_images', profileImage.path),
        );
      } else {
        return {
          "success": false,
          "error": "Profile image file does not exist",
        };
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      debugPrint("ApiService: Profile image upload response: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message":
              responseData["message"] ?? "Profile image uploaded successfully",
          "data": responseData["data"],
        };
      } else {
        return {
          "success": false,
          "error": responseData["error"] ?? "Failed to upload profile image",
        };
      }
    } catch (e) {
      debugPrint("ApiService: Error uploading profile image: $e");
      return {
        "success": false,
        "error": "Error uploading profile image: $e",
      };
    }
  }

  // Upload profile image to client_images table
  static Future<Map<String, dynamic>> uploadClientProfileImage(
    int userId,
    File profileImage,
  ) async {
    try {
      String token = await AuthService.getSessionToken();
      debugPrint(
          "ApiService: Uploading client profile image for user: $userId");

      final String endpoint = "$apiUrl/upload-client-profile-image/$userId";

      var request = http.MultipartRequest("POST", Uri.parse(endpoint));

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add user ID
      request.fields['user_id'] = userId.toString();

      // Add profile image file
      if (await profileImage.exists()) {
        debugPrint("ApiService: Adding client profile image to request");
        request.files.add(
          await http.MultipartFile.fromPath('client_images', profileImage.path),
        );
      } else {
        return {
          "success": false,
          "error": "Client profile image file does not exist",
        };
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      debugPrint(
          "ApiService: Client profile image upload response: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": responseData["message"] ??
              "Client profile image uploaded successfully",
          "data": responseData["data"],
        };
      } else {
        return {
          "success": false,
          "error":
              responseData["error"] ?? "Failed to upload client profile image",
        };
      }
    } catch (e) {
      debugPrint("ApiService: Error uploading client profile image: $e");
      return {
        "success": false,
        "error": "Error uploading client profile image: $e",
      };
    }
  }

  // Update FCM token for push notifications
  static Future<Map<String, dynamic>> updateFcmToken(
      String fcmToken, int userId) async {
    try {
      final token = await AuthService.getSessionToken();
      debugPrint("Updating FCM token for user $userId: $fcmToken");

      final response = await _client.put(
        Uri.parse("$apiUrl/update-fcm-token/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"fcm_token": fcmToken}),
      );

      debugPrint("FCM Token Update Status Code: ${response.statusCode}");
      debugPrint("FCM Token Update Response: ${response.body}");

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData["message"] ?? "FCM token updated successfully"
        };
      } else {
        return {
          "success": false,
          "error": responseData["error"] ?? "Failed to update FCM token"
        };
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating FCM token: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {"success": false, "error": "Failed to update FCM token: $e"};
    }
  }

  // Send push notification
  static Future<void> sendNotification(
      String fcmToken, String title, String body, int userId) async {
    try {
      final url = Uri.parse(
          'https://tzdthgosmoqepbypqbbu/functions/v1/notification_testing');

      final requestBody = {
        'fcm_token': fcmToken,
        'title': title,
        'body': body,
        'user_id': userId,
        'type': 'insert'
      };

      debugPrint("Sending notification with data:");
      debugPrint("URL: $url");
      debugPrint("Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint("Notification Response Status: ${response.statusCode}");
      debugPrint("Notification Response Body: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint(
            "Error: Notification request failed with status ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("Error sending notification: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  // Test notification functionality
  static Future<void> testNotification(String fcmToken, int userId) async {
    await sendNotification(fcmToken, "Test Notification",
        "This is a test notification from QTask", userId);
  }
// <<<<<<< add-upload-photo-in-verification-flow
//   // Upload profile image to tasker_images table
//   static Future<Map<String, dynamic>> uploadTaskerProfileImage(
//     int userId,
//     File profileImage,
//   ) async {
//     try {
//       String token = await AuthService.getSessionToken();
//       debugPrint("ApiService: Uploading profile image for user: $userId");

//       final String endpoint = "$apiUrl/upload-tasker-profile-image/$userId";

//       var request = http.MultipartRequest("POST", Uri.parse(endpoint));

//       request.headers.addAll({
//         "Authorization": "Bearer $token",
//         "Content-Type": "multipart/form-data",
//       });

//       // Add user ID
//       request.fields['user_id'] = userId.toString();

//       // Add profile image file
//       if (await profileImage.exists()) {
//         debugPrint("ApiService: Adding profile image to request");
//         request.files.add(
//           await http.MultipartFile.fromPath('tasker_images', profileImage.path),
//         );
//       } else {
//         return {
//           "success": false,
//           "error": "Profile image file does not exist",
//         };
//       }

//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//       final responseData = jsonDecode(responseBody);

//       debugPrint("ApiService: Profile image upload response: $responseData");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return {
//           "success": true,
//           "message":
//               responseData["message"] ?? "Profile image uploaded successfully",
//           "data": responseData["data"],
// =======
//   static Future<Map<String, dynamic>> updateFcmToken(
//       String fcmToken, int userId) async {
//     try {
//       final token = await AuthService.getSessionToken();
//       debugPrint("Updating FCM token for user $userId: $fcmToken");

//       final response = await _client.put(
//         Uri.parse("$apiUrl/update-fcm-token/$userId"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({"fcm_token": fcmToken}),
//       );

//       debugPrint("FCM Token Update Status Code: ${response.statusCode}");
//       debugPrint("FCM Token Update Response: ${response.body}");

//       final responseData = jsonDecode(response.body);
//       if (response.statusCode == 200) {
//         return {
//           "success": true,
//           "message": responseData["message"] ?? "FCM token updated successfully"
// >>>>>>> qtask-presentation
//         };
//       } else {
//         return {
//           "success": false,
// <<<<<<< add-upload-photo-in-verification-flow
//           "error": responseData["error"] ?? "Failed to upload profile image",
//         };
//       }
//     } catch (e) {
//       debugPrint("ApiService: Error uploading profile image: $e");
//       return {
//         "success": false,
//         "error": "Error uploading profile image: $e",
//       };
//     }
//   }
// =======
//           "error": responseData["error"] ?? "Failed to update FCM token"
//         };
//       }
//     } catch (e, stackTrace) {
//       debugPrint("Error updating FCM token: $e");
//       debugPrintStack(stackTrace: stackTrace);
//       return {"success": false, "error": "Failed to update FCM token: $e"};
//     }
//   }

//   static Future<void> sendNotification(
//       String fcmToken, String title, String body, int userId) async {
//     try {
//       final url = Uri.parse(
//           'https://tzdthgosmoqepbypqbbu/functions/v1/notification_testing');

//       final requestBody = {
//         'fcm_token': fcmToken,
//         'title': title,
//         'body': body,
//         'user_id': userId,
//         'type': 'insert'
//       };

//       debugPrint("Sending notification with data:");
//       debugPrint("URL: $url");
//       debugPrint("Request Body: ${jsonEncode(requestBody)}");

//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );

//       debugPrint("Notification Response Status: ${response.statusCode}");
//       debugPrint("Notification Response Body: ${response.body}");

//       if (response.statusCode != 200) {
//         debugPrint(
//             "Error: Notification request failed with status ${response.statusCode}");
//       }
//     } catch (e, stackTrace) {
//       debugPrint("Error sending notification: $e");
//       debugPrint("Stack trace: $stackTrace");
//     }
//   }

//   // Add this method to test notifications
//   static Future<void> testNotification(String fcmToken, int userId) async {
//     await sendNotification(fcmToken, "Test Notification",
//         "This is a test notification from QTask", userId);
//   }
// >>>>>>> qtask-presentation
}
