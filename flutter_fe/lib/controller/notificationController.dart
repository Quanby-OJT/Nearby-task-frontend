import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/notification_service.dart';

class NotificationController {
  final NotificationService _notificationService = NotificationService();
  final storage = GetStorage();

  Future<Map<String, dynamic>> getNotificationRequests(int userId) async {
    try {
      final data = await _notificationService.getNotificationRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting notifications"};
    }
  }

  Future<Map<String, dynamic>> getCancelledRequests(int userId) async {
    try {
      final data = await _notificationService.getCancelledRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting cancelled requests"};
    }
  }

  Future<Map<String, dynamic>> getRejectedRequests(int userId) async {
    try {
      final data = await _notificationService.getRejectedRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting rejected requests"};
    }
  }

  Future<Map<String, dynamic>> getPendingRequests(int userId) async {
    try {
      final data = await _notificationService.getPendingRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting pending requests"};
    }
  }

  Future<Map<String, dynamic>> getReviewRequests(int userId) async {
    try {
      final data = await _notificationService.getReviewRequests(userId);
      debugPrint(data.toString());
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting ongoing requests"};
    }
  }

  Future<Map<String, dynamic>> getOngoingRequests(int userId) async {
    try {
      final data = await _notificationService.getOngoingRequests(userId);
      debugPrint(data.toString());
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting ongoing requests"};
    }
  }

  Future<Map<String, dynamic>> getDisputedSettledRequests(int userId) async {
    try {
      final data =
          await _notificationService.getDisputedSettledRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {
        "error": "An error occurred while getting disputed settled requests"
      };
    }
  }

  Future<Map<String, dynamic>> getDisputedRequests(int userId) async {
    try {
      final data = await _notificationService.getDisputedRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting disputed requests"};
    }
  }

  Future<Map<String, dynamic>> getFinishRequests(int userId) async {
    try {
      final data = await _notificationService.getFinishRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting finish requests"};
    }
  }

  Future<Map<String, dynamic>> getConfirmedRequests(int userId) async {
    try {
      final data = await _notificationService.getConfirmedRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting confirmed requests"};
    }
  }
}
