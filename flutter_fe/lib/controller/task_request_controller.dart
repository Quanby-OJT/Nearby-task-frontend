import 'package:flutter/material.dart';
import 'package:flutter_fe/model/disputes.dart';
import 'package:flutter_fe/model/task_request.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/task_request_service.dart';

class TaskRequestController {
  final TaskRequestService _requestService = TaskRequestService();
  final TextEditingController rejectionController = TextEditingController();
  final TextEditingController otherReasonController = TextEditingController();
  final JobPostService jobPostService = JobPostService();

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

  Future<String> rejectTasker(int requestId, String rejectOrCancel) async {
    try {
      debugPrint("TaskRequestController: Rejecting tasker with ID $requestId");
      String rejectionReason = rejectionController.text;
      var response = await _requestService.rejectTaskerOrCancelTask(requestId, rejectOrCancel, rejectionReason);

      if(response.containsKey("message")){
        return response["message"];
      }else if(response.containsKey("error")){
        return response["error"];
      }else{
        return "Unknown Error";
      }
    }catch(e, stackTrace){
      debugPrint("Error in TaskRequestController.rejectTasker: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An Error Occured. Please Try Again.";
    }
  }

  Future<Disputes?> getDispute(int taskTakenId) async {
    try {
      if(taskTakenId == 0){
        return Disputes(
          disputeReason: "",
          disputeDetails: "",
          moderatorAction: "",
          moderatorNotes: ""
        );
      }
      final disputes = await jobPostService.getDispute(taskTakenId);
      if(disputes.containsKey('message')){
        return null;
      }else if(disputes.containsKey('error')){
        return null;
      }else{
        return Disputes.fromJson(disputes);
      }
    }catch(e, stackTrace){
      debugPrint("Error in TaskRequestController.getDispute: $e");
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
