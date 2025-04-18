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

  Future<Map<String, dynamic>> getRejectedRequests(int userId) async {
    try {
      final data = await _notificationService.getRejectedRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting rejected requests"};
    }
  }

  Future<Map<String, dynamic>> getOngoingRequests(int userId) async {
    try {
      final data = await _notificationService.getOngoingRequests(userId);
      return data;
    } catch (e, st) {
      debugPrint("Controller error: $e\nStacktrace: $st");
      return {"error": "An error occurred while getting ongoing requests"};
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
