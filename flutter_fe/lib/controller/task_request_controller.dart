import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_request.dart';
import 'package:flutter_fe/service/task_request_service.dart';

class TaskRequestController {
  final TaskRequestService _requestService = TaskRequestService();

  Future<List<TaskRequest>> getTaskerRequests() async {
    try {
      debugPrint(
          "TaskRequestController: Fetching tasker requests from database");
      // Always use the real implementation that fetches from the database
      final requests = await _requestService.getTaskerRequests();
      debugPrint("TaskRequestController: Fetched ${requests.length} requests");

      if (requests.isEmpty) {
        debugPrint("TaskRequestController: No requests found in database");
      } else {
        // Log the first request details
        final firstRequest = requests.first;
        debugPrint("TaskRequestController: First request details:");
        debugPrint("ID: ${firstRequest.requestId}");
        debugPrint("Status: ${firstRequest.status}");
        debugPrint("Task ID: ${firstRequest.task.id}");
        debugPrint("Client ID: ${firstRequest.client.id}");
      }

      return requests;
    } catch (e) {
      debugPrint("Error in TaskRequestController.getTaskerRequests: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> acceptRequest(int requestId) async {
    try {
      debugPrint("TaskRequestController: Accepting request with ID $requestId");
      final result = await _requestService.acceptTaskRequest(requestId);
      debugPrint("TaskRequestController: Accept result: $result");
      return result;
    } catch (e) {
      debugPrint("Error in TaskRequestController.acceptRequest: $e");
      return {
        'success': false,
        'message': 'Failed to accept request: $e',
      };
    }
  }

  Future<Map<String, dynamic>> declineRequest(int requestId) async {
    try {
      debugPrint("TaskRequestController: Declining request with ID $requestId");
      final result = await _requestService.declineTaskRequest(requestId);
      debugPrint("TaskRequestController: Decline result: $result");
      return result;
    } catch (e) {
      debugPrint("Error in TaskRequestController.declineRequest: $e");
      return {
        'success': false,
        'message': 'Failed to decline request: $e',
      };
    }
  }
}
