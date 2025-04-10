import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_request.dart';
import 'package:flutter_fe/service/task_request_service.dart';

class TaskRequestController {
  final TaskRequestService _requestService = TaskRequestService();
  final TextEditingController rejectionController = TextEditingController();
  final TextEditingController otherReasonController = TextEditingController();

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

  Future<Map<String, dynamic>> depositAmountToEscrow(double contractPrice, int taskTakenId) async{
    try{
      // debugPrint("TaskRequestController: Depositing amount to escrow");
      // debugPrint("TaskRequestController: Contract Price: $contractPrice");
      // debugPrint("TaskRequestController: Task Taken ID: $taskTakenId");
      if(contractPrice <= 0 || taskTakenId <= 0){
        return {"error": "Error while Processing Your Payment. Please Try Again."};
      }
      var response = await _requestService.depositEscrowPayment(contractPrice, taskTakenId);

      if(response['success']){
           return {"message": response['message'], "payment_url": response['payment_url']};
      }else{
        return {"error": response['error']};
      }
    }catch(e, st){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      return {"error": 'Error depositing amount to escrow. Please try again.'};
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

  Future<String> releaseEscrowPayment(int taskTakenId) async{
    try{
      debugPrint("TaskRequestController: Releasing escrow payment for task taken with ID $taskTakenId");
      var response = await _requestService.releaseEscrowPayment(taskTakenId);
      if(response.containsKey("message")){
        return response["message"];
      }else if(response.containsKey("error")){
        return response["error"];
      }else{
        return "Unknown Error";
      }
    }catch(e, stackTrace){
      debugPrint("Error in TaskRequestController.releaseEscrowPayment: $e");
      debugPrintStack(stackTrace: stackTrace);
      return "An Error Occured while releasing your payment. Please Try Again.";
    }
  }
}
