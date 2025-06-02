import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/chat_push_notifications.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/task_information.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';

import '../model/conversation.dart';

class TaskController {
  final JobPostService _jobPostService = JobPostService();
  final TaskDetailsService _taskDetailsService = TaskDetailsService();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final jobIdController = TextEditingController();
  final jobTitleController = TextEditingController();
  final jobSpecializationController = TextEditingController();
  final jobDescriptionController = TextEditingController();
  final jobLocationController = TextEditingController();
  final jobUrgencyController = TextEditingController();
  final contactPriceController = TextEditingController();
  final jobScopeController = TextEditingController();
  final jobRemarksController = TextEditingController();
  final contactpriceController = TextEditingController();
  final rejectionController = TextEditingController();
  final jobStartDateController = TextEditingController();
  final storage = GetStorage();

  void clearControllers() {
    jobIdController.clear();
    jobTitleController.clear();
    jobSpecializationController.clear();
    jobDescriptionController.clear();
    jobLocationController.clear();
    jobUrgencyController.clear();
    contactPriceController.clear();
    jobRemarksController.clear();
    contactpriceController.clear();
    rejectionController.clear();
  }

  Future<Map<String, dynamic>> updateJob(
    int id,
    String urgency,
    String scope,
    String workType, {
    List<String>? relatedSpecializationsIds,
    List<File>? photos,
    int? specializationId,
    String? selectedSpecialization,
    String? addressId,
  }) async {
    try {
      int userId = storage.read('user_id');
      final priceText = contactPriceController.text.trim();
      final priceInt = int.tryParse(priceText) ?? 0;

      if (priceInt > _escrowManagementController.tokenCredits.value) {
        return {
          "success": false,
          "error":
              "You don't have enough tokens to update your task. Please Deposit First Your Desired Amount of Tokens."
        };
      } else if (priceInt < 0) {
        return {"success": false, "error": "Please Input more than 0."};
      } else {
        final task = TaskModel(
            id: id,
            title: jobTitleController.text.trim(),
            description: jobDescriptionController.text.trim(),
            contactPrice: int.parse(contactPriceController.text.trim()),
            urgency: urgency,
            remarks: jobRemarksController.text.trim(),
            workType: workType,
            addressID: addressId,
            specializationId: specializationId,
            relatedSpecializationsIds: relatedSpecializationsIds,
            scope: scope,
            taskBeginDate: jobStartDateController.text,
            status: "Available");

        debugPrint("This is the task to update: ${task.toJson()}");

        final result =
            await _jobPostService.updateJob(task, task.id, files: photos);
        if (result['success'] == true) {
          return {
            'success': true,
            'message': result['message'] ?? 'Task updated successfully'
          };
        } else {
          return {
            'success': false,
            'error': result['error'] ?? 'Failed to update task'
          };
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in updateJob: $e');
      debugPrint(stackTrace.toString());
      return {
        'success': false,
        'error':
            'An Error Occurred while Updating Your Task. Please Try Again. If Issue Persists, contact our support.'
      };
    }
  }

  Future<Map<String, dynamic>> postJob(
      String specialization, String urgency, String scope, String workType,
      {List<String>? relatedSpecializationsIds,
      List<File>? photos,
      int? specializationId,
      bool? isVerifiedDocument,
      String? addressId}) async {
    try {
      int userId = storage.read('user_id');
      final priceText = contactPriceController.text.trim();
      final priceInt = int.tryParse(priceText) ?? 0;

      debugPrint(priceInt.toString());
      if (priceInt > _escrowManagementController.tokenCredits.value) {
        return {
          "success": false,
          "error":
              "You don't have enough tokens to post your needed task. Please Deposit First Your Desired Amount of Tokens."
        };
      } else if (priceInt < 0) {
        return {"success": false, "error": "Please Input more than 0."};
      } else {
        final task = TaskModel(
            id: 0,
            clientId: userId,
            title: jobTitleController.text.trim(),
            specialization: specialization,
            specializationId: specializationId,
            addressID: addressId,
            description: jobDescriptionController.text.trim(),
            relatedSpecializationsIds: relatedSpecializationsIds,
            isVerifiedDocument: isVerifiedDocument,
            urgency: urgency,
            contactPrice: int.parse(contactPriceController.text.trim()),
            scope: scope,
            remarks: jobRemarksController.text.trim(),
            workType: workType,
            taskBeginDate: jobStartDateController.text,
            status: "Available");

        return await _jobPostService.postJob(task, userId, files: photos);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in postJob: $e');
      debugPrint(stackTrace.toString());
      return {
        'success': false,
        'error':
            'An Error Occurred while Posting Your Task. Please Try Again. If Issue Persists, contact our support.'
      };
    }
  }

  Future<String> fetchIsAppliedID(
      int? taskId, int? clientId, int? taskerId) async {
    final assignedTask =
        await _jobPostService.fetchIsApplied(taskId, clientId, taskerId);

    debugPrint("Is applied response sample: ${assignedTask.toString()}");
    return assignedTask.containsKey('task') && assignedTask['task'] != null
        ? assignedTask['task']['task_taken_id'].toString()
        : assignedTask['error'].toString();
  }

  Future<List<TaskModel>> getJobsforClient(
      BuildContext context, int clientId) async {
    try {
      final clientTask = await _jobPostService.fetchJobsForClient(clientId);
      debugPrint("Client Task Response: ${clientTask.toString()}");

      if (clientTask.containsKey('success') &&
          clientTask['success'] &&
          clientTask['tasks'] is List) {
        final tasksList = clientTask['tasks'] as List<dynamic>;
        final taskTakenList = clientTask['taskTaken'] as List<dynamic>? ?? [];

        return tasksList.map((taskJson) {
          final matchingTaskTaken = taskTakenList
              .where((taskTaken) => taskTaken['task_id'] == taskJson['task_id'])
              .toList();

          return TaskModel.fromJson({
            ...taskJson as Map<String, dynamic>,
            'taskTaken': matchingTaskTaken,
          });
        }).toList();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clientTask['error']?.toString() ?? 'No tasks found'),
        ),
      );
      return [];
    } catch (e, stackTrace) {
      debugPrint("Error rendering created tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error while rendering your tasks. Please Try Again.')));
      return [];
    }
  }

  Future<List<TaskFetch?>> getTask(BuildContext context) async {
    final clientTask = await _jobPostService.fetchTasks();
    debugPrint("Task getTasks: ${clientTask.toString()}");

    if (clientTask.containsKey('data')) {
      List<dynamic> tasksList = clientTask['data'];
      List<TaskFetch> tasks =
          tasksList.map((task) => TaskFetch.fromJson(task)).toList();
      return tasks;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(clientTask['error'] ??
            "Something Went Wrong while Retrieving Your Tasks."),
      ),
    );
    return [];
  }

  Future<List<TaskFetch?>> getTaskClient(BuildContext context) async {
    final clientTask = await _jobPostService.fetchTasksClient();
    debugPrint("Task getTasks: ${clientTask.toString()}");

    if (clientTask.containsKey('data')) {
      List<dynamic> tasksList = clientTask['data'];
      List<TaskFetch> tasks =
          tasksList.map((task) => TaskFetch.fromJson(task)).toList();
      return tasks;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(clientTask['error'] ??
            "Something Went Wrong while Retrieving Your Tasks."),
      ),
    );
    return [];
  }

  Future<List<TaskModel>> getCreatedTasksByClient(int clientId) async {
    try {
      return await _jobPostService.fetchAssignTasksByClient(clientId);
    } catch (e, stackTrace) {
      debugPrint("Error fetching created tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> updateNotif(int taskTakenId, int userId) async {
    debugPrint("Assigning task...");
    final updateNotif =
        await _jobPostService.updateNotification(taskTakenId, userId);
    if (updateNotif.containsKey('message')) {
      return updateNotif['message'] = true;
    }
    return false;
  }

  Future<String> assignTask(
      int? taskId, int? clientId, int? taskerId, String role,
      {int? daysAvailable}) async {
    debugPrint("Assigning task...");
    debugPrint("Role: $role");
    final assignedTask = await _jobPostService.assignTask(
        taskId!, clientId!, taskerId!, role,
        daysAvailable: daysAvailable);
    return assignedTask.containsKey('message')
        ? assignedTask['message'].toString()
        : assignedTask['error'].toString();
  }

  Future<bool> acceptRequest(int taskTakenId, String value, String role,
      {String? rejectionReason}) async {
    debugPrint("Assigning task...");
    final assignedTask = await _jobPostService.acceptRequest(
        taskTakenId, value, role,
        rejectionReason: rejectionReason);
    if (assignedTask.containsKey('message')) {
      return assignedTask['message'] = true;
    }
    return false;
  }

  Future<String> fetchIsApplied(
      int? taskId, int? clientId, int? taskerId) async {
    final assignedTask =
        await _jobPostService.fetchIsApplied(taskId, clientId, taskerId);

    debugPrint("Is applied response: ${assignedTask.toString()}");
    return assignedTask.containsKey('message')
        ? assignedTask['message'].toString()
        : assignedTask['error'].toString();
  }

  Future<bool> raiseADispute(
      int taskTakenId,
      String value,
      String role,
      String reasonForDispute,
      String disputeDetails,
      List<File> imageEvidence) async {
    debugPrint("Assigning task...");
    debugPrint("Role: $role");
    debugPrint("Image Evidence: $imageEvidence");
    final assignedTask = await _jobPostService.raiseADispute(taskTakenId, value,
        role, imageEvidence, reasonForDispute, disputeDetails);
    if (assignedTask['success']) {
      return true;
    }
    return false;
  }

  Future<bool> rateTheTasker(
      int taskTakenId, int taskerId, int rating, String feedback) async {
    debugPrint(
        "Rating: $rating, Feedback: $feedback, Taken ID: $taskTakenId, Tasker ID: $taskerId");
    if (taskTakenId == 0 || rating == 0 || feedback.isEmpty) {
      return false;
    }

    try {
      Map<String, dynamic> feedbackResult = await _jobPostService.rateTheTasker(
          taskTakenId, taskerId, rating, feedback);

      debugPrint("Feedback response: $feedbackResult");
      if (feedbackResult.containsKey('message')) {
        return feedbackResult['success'];
      }
      debugPrint(
          "Error in task controller rateTheTasker: ${feedbackResult['error']}");
      return false;
    } catch (e, stackTrace) {
      debugPrint("Error in task controller rateTheTasker: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientFeedback(int taskTakenId) async {
    try {
      Map<String, dynamic> feedbackResult =
          await _jobPostService.getClientFeedback(taskTakenId);
      debugPrint("Feedback response: $feedbackResult");
      return feedbackResult;
    } catch (e, stackTrace) {
      debugPrint("Error in task controller getClientFeedback: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {
        "error":
            "An Error occured while retrieving your feedback. Please Try Again."
      };
    }
  }

  // Method to update a task
  Future<Map<String, dynamic>> updateTask(
      int taskId, Map<String, dynamic> taskData,
      {File? photo}) async {
    debugPrint("Updating task with ID: $taskId");
    try {
      if (_escrowManagementController.tokenCredits.value -
              taskData['proposed_price'] <
          _escrowManagementController.tokenCredits.value) {
        return {
          "success": false,
          "error":
              "You don't have enough tokens to post your needed task. Please Deposit First Your Desired Amount of Tokens."
        };
      } else {
        return await _jobPostService.updateTask(taskId, taskData, photo: photo);
      }
    } catch (e, stackTrace) {
      debugPrint("Error updating task: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {'success': false, 'error': 'Failed to update task: $e'};
    }
  }

  // Method to disable a task
  Future<Map<String, dynamic>> disableTask(int taskId) async {
    try {
      debugPrint("Disabling task with ID: $taskId");

      // First try to get valid statuses from the backend
      List<String> validStatuses =
          await _jobPostService.fetchValidTaskStatuses();
      debugPrint("Valid task statuses: $validStatuses");

      // Add some common variations just in case
      if (!validStatuses.contains("CANCELLED")) validStatuses.add("CANCELLED");
      if (!validStatuses.contains("cancelled")) validStatuses.add("cancelled");
      if (!validStatuses.contains("INACTIVE")) validStatuses.add("INACTIVE");
      if (!validStatuses.contains("inactive")) validStatuses.add("inactive");

      // Try with different status values
      Map<String, dynamic> result = {
        'success': false,
        'error': 'All status values failed'
      };

      for (String status in validStatuses) {
        debugPrint("Trying with status '$status'");
        result = await _jobPostService.disableTask(taskId, status);

        // If successful or error is not related to enum, break the loop
        if (result['success'] == true ||
            (result['error'] != null &&
                !result['error'].toString().contains("enum"))) {
          break;
        }
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint("Error disabling task: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {'success': false, 'error': 'Failed to disable task: $e'};
    }
  }

  Future<TaskAndConversationResult> fetchTasksAndConversations() async {
    try {
      final response = await _taskDetailsService.getAllTakenTasks();

      if (response.containsKey('error')) {
        debugPrint('Error fetching tasks: ${response['error']}');
        return TaskAndConversationResult(
          taskAssignments: [],
          conversations: [],
        );
      }

      // Parse task assignments
      final taskAssignments = (response['task_taken'] as List<dynamic>?)
              ?.map((taskJson) => TaskAssignment.fromJson(taskJson))
              .toList() ??
          [];

      // Parse conversations
      final conversations = (response['conversation'] as List<dynamic>?)
              ?.map((convJson) => Conversation.fromJson(convJson))
              .toList() ??
          [];

      debugPrint('Fetched tasks: $taskAssignments');
      debugPrint('Fetched conversations: $conversations');

      return TaskAndConversationResult(
        taskAssignments: taskAssignments,
        conversations: conversations,
      );
    } catch (e, st) {
      debugPrint('Error in fetchTasksAndConversations: $e');
      debugPrint(st.toString());
      return TaskAndConversationResult(
        taskAssignments: [],
        conversations: [],
      );
    }
  }

  // Method to delete a task
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      debugPrint("Deleting task with ID: $taskId");
      final result = await _jobPostService.deleteTask(taskId);
      return result;
    } catch (e, stackTrace) {
      debugPrint("Error deleting task: $e");
      debugPrintStack(stackTrace: stackTrace);
      return {'success': false, 'error': 'Failed to delete task: $e'};
    }
  }

//Update Task Status in Conversation
  Future<void> updateTaskStatus(
      BuildContext context, int taskTakenId, String? newStatus) async {
    try {
      final response =
          await _taskDetailsService.updateTaskStatus(taskTakenId, newStatus);

      if (response.containsKey("message")) {
        debugPrint('Task status updated successfully');
      } else {
        debugPrint('Failed to update task status: ${response["error"]}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating task status: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Method to check if a task is already assigned to a tasker
  Future<bool> isTaskAssignedToTasker(int taskId, int taskerId) async {
    try {
      return await _jobPostService.checkExistingAssignment(taskId, taskerId);
    } catch (e) {
      debugPrint("Error checking if task is assigned: $e");
      return false;
    }
  }
}
