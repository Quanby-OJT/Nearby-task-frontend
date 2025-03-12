// service/api_service.dart

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
      "http://10.0.2.2:5000/connect"; // Adjust if needed
  static final storage = GetStorage();

  static final http.Client _client = http.Client();
  static final Map<String, String> _cookies = {};

  static void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];

    if (rawCookie != null) {
      List<String> cookieParts = rawCookie.split(',');
      for (String part in cookieParts) {
        List<String> keyValue = part.split(';')[0].split('=');
        if (keyValue.length == 2) {
          _cookies[keyValue[0].trim()] = keyValue[1].trim();
        }
      }
      debugPrint('Updated Cookies: $_cookies'); // Debugging
    }
  }

  // Function to add cookies to requests
  static Map<String, String> _getHeaders() {
    String cookieHeader =
    _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return {
      "Content-Type": "application/json",
      if (_cookies.isNotEmpty) "Cookie": cookieHeader,
    };
  }

  static Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      // Create a salt using timestamp
      String salt = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _client.post(
        Uri.parse("$apiUrl/create-new-account"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          ...user.toJson(),
          "salt": salt,
        }),
      );

      var data = jsonDecode(response.body);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Request URL: $apiUrl/create-new-account');
      debugPrint('Full Request Body: ${user.toJson()}');

      if (response.statusCode == 201) {
        return {"message": data["message"] ?? "Registration Successful"};
      } else if (response.statusCode == 400) {
        // Handle errors field, which could be a string or a list
        if (data['errors'] is String) {
          // If errors is a string, return it directly
          return {"error": data['errors']};
        } else if (data['errors'] is List) {
          // If errors is a list, map it to a single string
          List<dynamic> errors = data['errors'];
          String errorMessage = errors.map((e) => e['msg'] ?? e.toString()).join('\n');
          return {"error": errorMessage};
        } else {
          return {"error": "Unknown error format from server"};
        }
      } else {
        return {
          "error": data["error"] ?? "An error occurred while registering your account. Please try again."
        };
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      return {
        "error": "An error occurred while registering your account: $e"
      };
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String token, String email) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/verify"),
        headers: _getHeaders(),
        body: json.encode({
          "token": token,
          "email": email
        }
      ));

      var data = jsonDecode(response.body);
      debugPrint('Verify Response: ${response.statusCode} - ${response.body}');

      if(response.statusCode == 200){
        return {"message": data["message"] ?? "Email Verified Successfully.", "user_id": data["user_id"], "session": data["session"]};
      }else {
        return {"error": data["error"] ?? "An Error Occured while verifying your email. Please Try Again"};
      }
    }catch(e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      return {"error": "An Error Occured while verifying your email. Please Try Again"};
    }
  }

  // static Future<bool> createTasker(TaskerModel tasker){
  //   var request = http.MultipartRequest("POST", Uri.parse("$apiUrl/"))
  // }

  static Future<Map<String, dynamic>> fetchAuthenticatedUser(String userId) async {
    try {
      final String token = await AuthService.getSessionToken();
      final response = await http.get(
          Uri.parse("$apiUrl/getUserData/$userId"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          }
      );

      debugPrint("Retreived Data: " + response.body);
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        UserModel user = UserModel.fromJson(data['user']);
        if(data['user']['user_role'] == "Client"){
          ClientModel client = ClientModel.fromJson(data['client']);
          return{"user": user, "client": client};
        }else if(data['user']['user_role'] == "Tasker"){
          TaskerModel tasker = TaskerModel.fromJson(data['tasker']);
          return{"user": user, "tasker": tasker};
        }else{
          return{"error": data['error'] ?? "An Error Occured while retrieving data"};
        }
      } else {
        return {"error": data['error'] ?? "Failed to fetch user data"};
      }
    } catch (e) {
      debugPrint(e.toString());
      debugPrintStack();
      return {"error": "An error occurred while retrieving your information. Please try again."};
    }
  }

  static Future<Map<String, dynamic>> authUser(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse("$apiUrl/login-auth"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      _updateCookies(response);

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
    } catch (e) {
      debugPrint('Error: $e');
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
      _updateCookies(response); // 🔥 Store session cookies

      var data = json.decode(response.body);
      debugPrint('Decoded Data Type: ${data.runtimeType}');
      debugPrint('Response Data: $data'); // Debugging

      if (response.statusCode == 200) {
        return {"user_id": data['user_id'], "role": data['user_role'], "session": data['session']};
      } else if (response.statusCode == 400 && data.containsKey('errors')) {
        List<dynamic> errors = data['errors'];
        String validationMessage = errors.map((e) => e['msg']).join("\n");
        debugPrint(validationMessage);
        return {"validation_error": validationMessage};
      } else {
        return {"error": data['error'] ?? "OTP Authentication Failed"};
      }
    } catch (e) {
      debugPrint('Error: $e');
      return {"error": "An error occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> logout(int userId, String session) async {
    try{
      final response = await http.post(
        Uri.parse("$apiUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $session",
          "Access-Control-Allow-Credentials": "true"
        },
        body: json.encode({
          "user_id": userId,
          "session": session
        }),
      );

      debugPrint('Logout Status Code: ${response.statusCode}');
      debugPrint('Logout Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _cookies.remove("session"); // Remove only the session cookie
        return {"message": "Logged out successfully"};
      } else {
        var data = json.decode(response.body);
        return {"error": data['message'] ?? "Failed to logout"};
      }
    } catch (e) {
      debugPrint('Logout Error: $e');
      return {"error": "Connection error during logout"};
    }
  }
  
  static Future<Map<String, dynamic>> sendMessage(Conversation conversation) async {
    try {
      String token = await AuthService.getSessionToken();
      final response = await http.post(
        Uri.parse("$apiUrl/send-message"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: {
          conversation.toJson()
        }
      );

      var data = jsonDecode(response.body);

      if(response.statusCode == 200){
        return {"message": data["message"] ?? "Successfully Sent the Message"};
      }else if(response.statusCode == 400){
        return{"error": data["errors"] ?? "Please Check Your inputs and try again"};
      } else {
        // Handle unexpected response statuses
        return {"error": "Unexpected error occurred. Status code: ${response.statusCode}"};
      }
    }catch (e) {
      debugPrintStack();
      return {"error": "An Error Occured while Sending a Message. Please Try Again"};
    }
  }

  static Future<Map<String, dynamic>> getMessages(int taskTakenId) async {
    try{
      String token = await AuthService.getSessionToken();

      final response = await http.get(
        Uri.parse("$apiUrl/task/$taskTakenId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        }
      );

      var data = jsonDecode(response.body);

      if(response.statusCode == 200){
        Conversation messages = Conversation.fromJson(data['messages']);
        return {"messages": messages};
      }else{
        return {"error": data['error']};
      }
    }catch(e, st){
      debugPrint(e.toString());
      debugPrint(st.toString());
      return {"error": "An Error Occured while retrieving your conversation. Please Try Again."};
    }
  }
} 
