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

  Future<void> depositAmountToEscrow(BuildContext context, double contractPrice, int taskTakenId) async{
    try{
      debugPrint("TaskRequestController: Depositing amount to escrow");
      debugPrint("TaskRequestController: Contract Price: $contractPrice");
      debugPrint("TaskRequestController: Task Taken ID: $taskTakenId");
      if(contractPrice <= 0 || taskTakenId <= 0){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error while Processing Your Payment. Please Try Again."),
          ),
        );
        return;
      }
      var response = await _requestService.depositEscrowPayment(contractPrice, taskTakenId);

      if(response.containsKey('message')){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
          ),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error']),
          ),
        );
      }
    }catch(e, st){
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error depositing amount to escrow. Please try again.'),
        ),
      );
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
