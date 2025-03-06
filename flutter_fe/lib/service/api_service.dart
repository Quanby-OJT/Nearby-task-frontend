// service/api_service.dart

import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/user_model.dart';
import '../model/tasker_model.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String apiUrl = "http://10.0.2.2:5000/connect"; // Adjust if needed
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
      print('Updated Cookies: $_cookies'); // Debugging
    }
  }

  // Function to add cookies to requests
  static Map<String, String> _getHeaders() {
    String cookieHeader =
    _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_cookies.isNotEmpty) "Cookie": cookieHeader,
    };
  }

  static Future<bool> registerUser(UserModel user) async {
    //Tell Which Route the Backend we going to Use
    var request =
    http.MultipartRequest("POST", Uri.parse("$apiUrl/create-new-user"));

    // Add text fields
    request.fields["first_name"] = user.firstName;
    request.fields["middle_name"] = request.fields["last_name"] = user.lastName;
    request.fields["email"] = user.email;
    request.fields["password"] = user.password ?? "";
    request.fields["user_role"] = user.role;

    //Attach Image (if available)~
    if (user.image != null && user.imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_link',
          user.image!,
          filename: user.imageName!,
        ),
      );
    }

    var response = await request.send();
    return response.statusCode == 201;
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
      print(e.toString());
      return {"error": "An error occurred: $e"};
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

      _updateCookies(response); // 🔥 Store session cookies here

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
      print('Error: $e');
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

      // debugPrint("Request Fields: ${request.fields}");
      // debugPrint(
      //     "Request Files: ${request.files.map((file) => file.filename).toList()}");
      // debugPrint("Request URL: ${request.url}");

      // var response = await request.send();
      // return response.statusCode == 201;

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
      print('Error: $e');
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

      //print('Sent Headers: ${_getHeaders()}'); // Debugging
      _updateCookies(response); // 🔥 Store session cookies

      var data = json.decode(response.body);
      // print('Decoded Data Type: ${data.runtimeType}');
      // print("Data: $data");

      if (response.statusCode == 200) {
        return {"user_id": data['user_id'], "role": data['user_role'], "session": data['session_id']};
      } else if (response.statusCode == 400 && data.containsKey('errors')) {
        List<dynamic> errors = data['errors'];
        String validationMessage = errors.map((e) => e['msg']).join("\n");
        print(validationMessage);
        return {"validation_error": validationMessage};
      } else {
        return {"error": data['error'] ?? "OTP Authentication Failed"};
      }
    } catch (e) {
      print('Error: $e');
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
        _cookies.clear();
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
}
