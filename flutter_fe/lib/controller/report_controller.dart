import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/report_model.dart';
import 'package:flutter_fe/service/report_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportController {
  final ReportService _reportService = ReportService();
  final reasonController = TextEditingController();
  List<XFile> selectedImages = [];
  Map<String, String> errors = {};
  String? imageUploadError;
  List<Map<String, dynamic>> taskers = [];
  List<Map<String, dynamic>> clients = [];

  Future<void> fetchTaskers() async {
    try {
      debugPrint("Fetching taskers...");
      final response = await http.get(
        Uri.parse("${ReportService.apiUrl}/taskers"),
        headers: {
          'Authorization': "Bearer ${ReportService.token}",
        },
      );

      debugPrint("Taskers API Response Status: ${response.statusCode}");
      debugPrint("Taskers API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          taskers = List<Map<String, dynamic>>.from(data['taskers']);
          debugPrint("Successfully fetched ${taskers.length} taskers");
        } else {
          debugPrint("Failed to fetch taskers: ${data['message']}");
          taskers = [];
        }
      } else {
        debugPrint("Error fetching taskers: ${response.statusCode}");
        taskers = [];
      }
    } catch (e) {
      debugPrint("Exception while fetching taskers: $e");
      taskers = [];
    }
  }

  Future<void> fetchClients() async {
    try {
      debugPrint("Fetching clients...");
      final response = await http.get(
        Uri.parse("${ReportService.apiUrl}/clients"),
        headers: {
          'Authorization': "Bearer ${ReportService.token}",
        },
      );

      debugPrint("Clients API Response Status: ${response.statusCode}");
      debugPrint("Clients API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          clients = List<Map<String, dynamic>>.from(data['clients']);
          debugPrint("Successfully fetched ${clients.length} clients");
        } else {
          debugPrint("Failed to fetch clients: ${data['message']}");
          clients = [];
        }
      } else {
        debugPrint("Error fetching clients: ${response.statusCode}");
        clients = [];
      }
    } catch (e) {
      debugPrint("Exception while fetching clients: $e");
      clients = [];
    }
  }

  Future<void> pickImages(BuildContext context) async {
    const int maxImages = 5;
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      if (selectedImages.length + images.length <= maxImages) {
        selectedImages.addAll(images);
        imageUploadError = null;
      } else {
        imageUploadError = 'You can only upload up to $maxImages images.';
      }
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void validateAndSubmit(BuildContext context, StateSetter setModalState,
      int reportedBy, int? reportedWhom) {
    errors.clear();

    if (reasonController.text.trim().isEmpty) {
      errors['reason'] = 'Please enter a reason';
    }

    if (reportedWhom == null) {
      errors['reported_whom'] = 'Please select a user to report';
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Since we return early if reportedWhom is null, we can safely assert it's non-null here
    _submitReport(context, setModalState, reportedBy, reportedWhom!);
  }

  Future<void> _submitReport(BuildContext context, StateSetter setModalState,
      int reportedBy, int reportedWhom) async {
    final report = ReportModel(
      reason: reasonController.text.trim(),
      images: selectedImages,
      reportedBy: reportedBy, // Pass the current user's user_id
      reportedWhom: reportedWhom, // Pass the selected user's user_id
    );

    debugPrint("JSON Data being sent to backend: ${report.toJson()}");

    try {
      final result = await _reportService.submitReport(report);
      debugPrint("Backend response: $result");

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Report Submitted!"),
            backgroundColor: Colors.green,
          ),
        );
        clearForm();
      } else {
        if (result.containsKey('errors') && result['errors'] is List) {
          for (var error in result['errors']) {
            if (error is Map<String, dynamic> &&
                error.containsKey('path') &&
                error.containsKey('msg')) {
              errors[error['path']] = error['msg'];
            }
          }
          setModalState(() {});
        } else if (result.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void clearForm() {
    reasonController.clear();
    selectedImages.clear();
    errors.clear();
    imageUploadError = null;
  }
}
