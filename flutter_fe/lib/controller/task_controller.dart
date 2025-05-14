import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/task_information.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';

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
  final jobDurationController = TextEditingController();
  final jobTimeController = TextEditingController();
  final jobUrgencyController = TextEditingController();
  final contactPriceController = TextEditingController();
  final jobRemarksController = TextEditingController();
  final jobTaskBeginDateController = TextEditingController();
  final contactpriceController = TextEditingController();
  final rejectionController = TextEditingController();
  final storage = GetStorage();

  Future<Map<String, dynamic>> postJob(String specialization, String urgency,
      String period, String workType) async {
    try {
      int userId = storage.read('user_id');
      print('Submitting data...');

      // Parse the duration as an integer
      final durationText = jobTimeController.text.trim();
      final durationInt = int.tryParse(durationText) ?? 0;

      // Parse the price as an integer
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
            description: jobDescriptionController.text.trim(),
            location: jobLocationController.text.trim(),
            duration: durationInt.toString(),
            period: period,
            urgency: urgency,
            contactPrice: priceInt,
            remarks: jobRemarksController.text.trim(),
            taskBeginDate: jobTaskBeginDateController.text.trim(),
            workType: workType,
            status: "Available");

        print('Task data: ${task.toJson()}');
        return await _jobPostService.postJob(task, userId);
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

  Future<List<TaskModel?>> getJobsforClient(
      BuildContext context, int clientId) async {
    final clientTask = await _jobPostService.fetchJobsForClient(clientId);
    debugPrint("Client Task: ${clientTask.toString()}");

    if (clientTask.containsKey('tasks')) {
      List<dynamic> tasksList = clientTask['tasks'];
      List<TaskModel> tasks =
          tasksList.map((task) => TaskModel.fromJson(task)).toList();
      return tasks;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(clientTask['error'] ??
              "Something Went Wrong while Retrieving Your Tasks.")),
    );
    return [];
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

  Future<List<TaskModel>> getCreatedTasksByClient(int clientId) async {
    try {
      return await _jobPostService.fetchCreatedTasksByClient(clientId);
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
      int? taskId, int? clientId, int? taskerId, String role) async {
    debugPrint("Assigning task...");
    debugPrint("Role: $role");
    final assignedTask =
        await _jobPostService.assignTask(taskId!, clientId!, taskerId!, role);
    return assignedTask.containsKey('message')
        ? assignedTask['message'].toString()
        : assignedTask['error'].toString();
  }

  Future<bool> acceptRequest(int taskTakenId, String value, String role) async {
    debugPrint("Assigning task...");
    final assignedTask =
        await _jobPostService.acceptRequest(taskTakenId, value, role);
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

  // Method to update a task
  Future<Map<String, dynamic>> updateTask(
      int taskId, Map<String, dynamic> taskData) async {
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
        return await _jobPostService.updateTask(taskId, taskData);
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

  Future<List<TaskAssignment>> getAllAssignedTasks(
      BuildContext context, int userId) async {
    final assignedTasks = await TaskDetailsService().getAllTakenTasks();
    debugPrint("Assigned Tasks: ${assignedTasks.toString()}");

    try {
      if (assignedTasks.containsKey('data') && assignedTasks['data'] != null) {
        List<dynamic> dataList = assignedTasks['data'] as List<dynamic>;
        List<TaskAssignment> taskAssignments = dataList.map((item) {
          // Safely handle task_taken_id
          dynamic taskTakenIdRaw = item['task_taken_id'];
          int taskTakenId;
          if (taskTakenIdRaw is int) {
            taskTakenId = taskTakenIdRaw;
          } else if (taskTakenIdRaw is String) {
            taskTakenId = int.tryParse(taskTakenIdRaw) ??
                0; // Fallback to 0 if parsing fails
          } else {
            taskTakenId = 0; // Fallback for unexpected types
          }

          // Parse task data
          Map<String, dynamic> taskData =
              item['post_task'] as Map<String, dynamic>;
          TaskModel task = TaskModel(
            id: taskData['task_id'] is int
                ? taskData['task_id']
                : int.tryParse(taskData['task_id'].toString()) ?? 0,
            title: taskData['task_title'] as String? ?? 'Untitled',
            clientId: null,
            specialization: '',
            description: '',
            location: '',
            period: '',
            duration: '',
            urgency: '',
            status: '',
            contactPrice: 0,
            remarks: null,
            taskBeginDate: '',
            workType: '',
          );

          // Parse client data
          Map<String, dynamic> clientData =
              item['clients'] as Map<String, dynamic>;
          Map<String, dynamic> clientUserData =
              clientData['user'] as Map<String, dynamic>;
          UserModel clientUser = UserModel(
            firstName: clientUserData['first_name'] as String? ?? '',
            middleName: clientUserData['middle_name'] as String? ?? '',
            lastName: clientUserData['last_name'] as String? ?? '',
            email: '',
            role: '',
            accStatus: '',
          );
          ClientModel client = ClientModel(
            preferences: '',
            clientAddress: '',
            user: clientUser,
          );

          // Parse tasker data
          Map<String, dynamic> taskerData = item['tasker'] != null
              ? item['tasker'] as Map<String, dynamic>
              : {};
          Map<String, dynamic> taskerUserData = taskerData['user'] ?? {};
          UserModel taskerUser = UserModel(
            firstName: taskerUserData['first_name'] as String? ?? '',
            middleName: taskerUserData['middle_name'] as String? ?? '',
            lastName: taskerUserData['last_name'] as String? ?? '',
            email: '',
            role: '',
            accStatus: '',
          );
          TaskerModel tasker = TaskerModel(
            id: 0,
            bio: '',
            specialization: '',
            skills: '',
            availability: false,
            wage: 0.0,
            payPeriod: '',
            birthDate: DateTime.now(),
            group: false,
            user: taskerUser,
            rating: 0,
          );

          // Create TaskAssignment
          TaskAssignment assignment = TaskAssignment(
            client: client,
            tasker: tasker,
            task: task,
            taskTakenId: taskTakenId,
            taskStatus: item['task_status'] as String? ?? 'unknown',
          );
          debugPrint('Parsed Assignment: $assignment');
          return assignment;
        }).toList();
        return taskAssignments;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assignedTasks['error'] ??
                'Something went wrong while retrieving your tasks.'),
          ),
        );
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("Error getting all assigned tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
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
