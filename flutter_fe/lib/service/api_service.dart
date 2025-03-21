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

class ApiService {
  static const String apiUrl =
      "http://localhost:5000/connect"; // Adjust if needed
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "message":
              data["message"] ?? "User information updated successfully!",
          "user": data["user"]
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
      return {
        "errors": "An error occurred during updating user information: $e"
      };
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

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": data["message"] ??
              "User information with profile image updated successfully!",
          "user": data["user"]
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

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": data["message"] ??
              "User information with ID image updated successfully!",
          "user": data["user"]
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

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          "message": data["message"] ??
              "User information with images updated successfully!",
          "user": data["user"],
          "profileImage": data["profileImage"],
          "idImage": data["idImage"],
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

  static Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      // Create a salt using timestamp
      String salt = DateTime.now().millisecondsSinceEpoch.toString();

      // Create the request payload
      // Map<String, dynamic> requestBody = {
      //   "data": {
      //     "first_name": user.firstName,
      //     "middle_name": user.middleName,
      //     "last_name": user.lastName,
      //     "email": user.email,
      //     "password": user.password,
      //     "user_role": user.role,
      //     // "acc_status": user.accStatus
      //   },
      //   "salt": salt
      // };

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          "message": data["message"] ??
              "Registration successful! Please check your email to verify your account.",
          "user": data["user"]
        };
      } else if (response.statusCode == 400) {
        if (data['errors'] is String) {
          return {"errors": data['errors']};
        } else if (data['errors'] is List) {
          String errorMessage = (data['errors'] as List)
              .map((e) => e['msg'] ?? e.toString())
              .join('\n');
          return {"errors": errorMessage};
        }
        return {"errors": "Registration failed. Please try again."};
      } else {
        return {
          "errors": data["error"] ??
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
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _updateCookies(response);
        return {
          "message": data["message"] ?? "Email verified successfully",
          "user_id": data["user_id"],
          "session": data["session"]
        };
      } else {
        return {
          "error":
              data["error"] ?? "Email verification failed. Please try again."
        };
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      return {"error": "An error occurred during email verification: $e"};
    }
  }

//   static Future<Map<String, dynamic>> verifyEmail(
//       String token, String email) async {
//     try {
//       debugPrint('Starting email verification for: $email with token: $token');
//       final response = await _client.post(
//         Uri.parse("$apiUrl/verify"),
//         headers: _getHeaders(),
//         body: json.encode({"token": token, "email": email}),
//       );

//       debugPrint('Verify Response Status: ${response.statusCode}');
//       debugPrint('Verify Response Body: ${response.body}');

//       if (response.body.isEmpty) {
//         debugPrint('Error: Response body is empty');
//         return {"error": "Empty response from server"};
//       }

//       var data = jsonDecode(response.body);
//       debugPrint('Decoded Response Data: $data');

//       if (response.statusCode == 200) {
//         return {
//           "message":
//               data["message"]?.toString() ?? "Email Verified Successfully.",
//           "user_id": data["user_id"], // Convert to string for consistency
//           "token": data["session"],
//         };
//       } else {
//         debugPrint('Non-200 status code: ${response.statusCode}');
//         return {
//           "error": data["error"]?.toString() ??
//               "An error occurred while verifying your email. Please try again."
//         };
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Verification Error: $e');
//       debugPrint('Stack Trace: $stackTrace');
//       return {
//         "error":
//             "An error occurred while verifying your email. Please try again."
//       };
//     }
//   }

  //Creating Tasker/Client Information but needs authentication token from the backend.
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
          // Adjust content type if necessary (e.g., image/png)
        ),
      ]);

      var response = await request.send();

      debugPrint("Status Code: ${response.statusCode}");
      var body = await response.stream.bytesToString();
      var data = jsonDecode(body);
      debugPrint("Response Data: $data");

      if (response.statusCode == 201) {
        return {
          "message": data["message"] ??
              "Profile Created Successfully. Please Wait for Our Team to Verify Your Account"
        };
      } else if (response.statusCode == 400) {
        return {
          "error": data["errors"] ?? "Please Check Your inputs and try again"
        };
      } else {
        return {
          "error": data["error"] ??
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

      debugPrint("Retreived Data: ${response.body}");
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        UserModel user = UserModel.fromJson(data['user']);
        if (data['user']['user_role'] == "Client") {
          ClientModel client = ClientModel.fromJson(data['client']);
          return {"user": user, "client": client};
        } else if (data['user']['user_role'] == "Tasker") {
          TaskerModel tasker = TaskerModel.fromJson(data['tasker']);
          return {"user": user, "tasker": tasker};
        } else {
          return {
            "error": data['error'] ?? "An Error Occured while retrieving data"
          };
        }
      } else {
        return {"error": data['error'] ?? "Failed to fetch user data"};
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

      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"user_id": data['user_id']};
      } else if (response.statusCode == 400 && data.containsKey('errors')) {
        List<dynamic> errors = data['errors'];
        String errorMessage = errors.map((e) => e['msg']).join('\n');
        return {"validation_error": errorMessage};
      } else {
        return {"error": data['error'] ?? 'Authentication Failed'};
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

      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {"message": data['message']};
      } else if (response.statusCode == 400 && data.containsKey('errors')) {
        // Handle validation errors from backend
        List<dynamic> errors = data['errors'];
        String validationMessage = errors.map((e) => e['message']).join("\n");
        return {"validation_error": validationMessage};
      } else {
        return {"error": data['error'] ?? "OTP Generation Failed"};
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

      var data = json.decode(response.body);
      debugPrint('Decoded Data Type: ${data.runtimeType}');
      debugPrint('Response Data: $data'); // Debugging

      if (response.statusCode == 200) {
        // Extract session from cookies if not in response data
        String? sessionFromCookies = _cookies['session'];
        debugPrint('Session from cookies: $sessionFromCookies');

        return {
          "user_id": data['user_id'],
          "role": data['user_role'],
          "session": data['session'] ?? sessionFromCookies ?? ""
        };
      } else if (response.statusCode == 400 && data.containsKey('errors')) {
        List<dynamic> errors = data['errors'];
        String validationMessage = errors.map((e) => e['msg']).join("\n");
        debugPrint(validationMessage);
        return {"validation_error": validationMessage};
      } else {
        return {
          "error":
              data['error'] ?? "OTP Authentication Failed. Please Try again."
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
        var data = json.decode(response.body);
        return {"error": data['error'] ?? "Failed to logout"};
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

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"message": data["message"] ?? "Successfully Sent the Message"};
      } else if (response.statusCode == 400) {
        return {
          "error": data["errors"] ?? "Please Check Your inputs and try again"
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

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] != null && data['data'] is List) {
          return {"messages": data['data']}; // Return the list directly
        } else {
          return {}; // No messages found
        }
      } else {
        return {"error": data['error'] ?? "Failed to retrieve messages"};
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

  static Map<String, String> _getHeaders() {
    String cookieHeader =
        _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_cookies.isNotEmpty) "Cookie": cookieHeader,
    };
  }
}
