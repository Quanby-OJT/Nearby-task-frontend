import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_fe/config/url_strategy.dart';
import 'package:flutter_fe/model/report_model.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ReportService {
  static String url = apiUrl ?? "https://192.168.43.15:5000/connect";
  static final storage = GetStorage();
  static final token = storage.read('session');

  Future<Map<String, dynamic>> submitReport(ReportModel report) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$url/reports"),
      );

      request.headers['Authorization'] = "Bearer $token";

      // Add all fields from report.toJson() to request.fields
      final reportJson = report.toJson();
      request.fields['reason'] = reportJson['reason'] ?? '';
      request.fields['reported_by'] =
          reportJson['reported_by']?.toString() ?? '';
      request.fields['reported_whom'] =
          reportJson['reported_whom']?.toString() ?? '';

      if (report.images != null && report.images!.isNotEmpty) {
        for (var image in report.images!) {
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes(
                'images[]',
                bytes,
                filename: image.name,
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath('images[]', image.path),
            );
          }
        }
      }

      debugPrint(
          "Data being sent to backend: ${request.fields}, images=${report.images?.length ?? 0}");

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      debugPrint("Raw backend response: ${responseBody.body}");
      debugPrint("Response status code: ${response.statusCode}");

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
