import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Add this to check if running on web
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/report_model.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ReportService {
  static const String apiUrl = "http://localhost:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');

  Future<Map<String, dynamic>> submitReport(ReportModel report) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$apiUrl/reports"),
      );

      // Add headers (optional)
      request.headers['Authorization'] = "Bearer $token" ?? '';

      // Add the reason field
      request.fields['reason'] = report.reason ?? '';

      // Add the images under the key 'images[]'
      if (report.images != null && report.images!.isNotEmpty) {
        for (var image in report.images!) {
          if (kIsWeb) {
            // For web: Use MultipartFile.fromBytes
            final bytes = await image.readAsBytes(); // Read the image as bytes
            request.files.add(
              http.MultipartFile.fromBytes(
                'images[]',
                bytes,
                filename: image.name, // Use the file name
              ),
            );
          } else {
            // For non-web (mobile/desktop): Use MultipartFile.fromPath
            request.files.add(
              await http.MultipartFile.fromPath('images[]', image.path),
            );
          }
        }
      }

      // Log the data being sent
      debugPrint(
          "Data being sent to backend: reason=${report.reason}, images=${report.images?.length ?? 0}");

      // Send the request
      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      // Log the raw response for debugging
      debugPrint("Raw backend response: ${responseBody.body}");
      debugPrint("Response status code: ${response.statusCode}");

      // Check if the response is JSON
      if (response.statusCode >= 200 && response.statusCode < 300) {
        var contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final responseData = jsonDecode(responseBody.body);
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Report submitted successfully',
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message':
                'Unexpected response format: Expected JSON, got $contentType',
            'raw_response': responseBody.body,
          };
        }
      } else {
        var contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final responseData = jsonDecode(responseBody.body);
          return {
            'success': false,
            'message': responseData['error'] ?? 'Unknown error',
            'errors': responseData['errors'],
          };
        } else {
          return {
            'success': false,
            'message':
                'Error: Server returned status code ${response.statusCode}',
            'raw_response': responseBody.body,
          };
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      debugPrintStack();
      return {'success': false, 'message': "Error: $e"};
    }
  }
}
