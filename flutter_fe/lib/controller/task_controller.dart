import 'package:flutter/material.dart';
import 'package:flutter_fe/model/client_model.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/task_information.dart';
import 'package:get_storage/get_storage.dart';

class TaskController {
  final JobPostService _jobPostService = JobPostService();
  final TaskDetailsService _taskDetailsService = TaskDetailsService();
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
  final storage = GetStorage();

  Future<Map<String, dynamic>> postJob(String? specialization, String? urgency,
      String? period, String? workType) async {
    try {
      int userId = storage.read('user_id');
      print('Submitting data...');

      // Parse the duration as an integer
      final durationText = jobTimeController.text.trim();
      final durationInt = int.tryParse(durationText) ?? 0;

      // Parse the price as an integer
      final priceText = contactPriceController.text.trim();
      final priceInt = int.tryParse(priceText) ?? 0;

      final task = TaskModel(
        id: 0,
        clientId: userId,
        title: jobTitleController.text.trim(),
        specialization: specialization,
        description: jobDescriptionController.text.trim(),
        location: jobLocationController.text.trim(),
        duration: durationInt.toString(),
        // Use the parsed integer value
        period: period,
        urgency: urgency,
        contactPrice: priceInt,
        // Use the parsed integer value
        remarks: jobRemarksController.text.trim(),
        taskBeginDate: jobTaskBeginDateController.text.trim(),
        workType: workType, // New field
      );

      print('Task data: ${task.toJson()}');
      return await _jobPostService.postJob(task, userId);
    } catch (e, stackTrace) {
      print('Error in postJob: $e');
      debugPrint(stackTrace.toString());
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<List<TaskModel?>> getJobsforClient(
      BuildContext context, int clientId) async {
    final clientTask = await _jobPostService.fetchJobsForClient(clientId);
    debugPrint(clientTask.toString());

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

  Future<List<TaskModel>> getCreatedTasksByClient(int clientId) async {
    try {
      return await _jobPostService.fetchCreatedTasksByClient(clientId);
    } catch (e, stackTrace) {
      debugPrint("Error fetching created tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<String> assignTask(int? taskId, int? clientId, int? taskerId) async {
    debugPrint("Assigning task...");
    final assignedTask =
        await _jobPostService.assignTask(taskId, clientId, taskerId);
    return assignedTask.containsKey('message')
        ? assignedTask['message'].toString()
        : assignedTask['error'].toString();
  }

  // Method to update a task
  Future<Map<String, dynamic>> updateTask(
      int taskId, Map<String, dynamic> taskData) async {
    try {
      debugPrint("Updating task with ID: $taskId");
      final result = await _jobPostService.updateTask(taskId, taskData);
      return result;
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

  //All Messages to client/tasker
  Future<List<TaskAssignment>?> getAllAssignedTasks(
      BuildContext context, int userId) async {
    final assignedTasks = await TaskDetailsService().getAllTakenTasks();
    debugPrint(assignedTasks.toString());

    if (assignedTasks.containsKey('data') && assignedTasks['data'] != null) {
      List<dynamic> dataList = assignedTasks['data'] as List<dynamic>;
      List<TaskAssignment> taskAssignments = dataList.map((item) {
        // Parse tasks from post_task
        Map<String, dynamic> taskData =
            item['post_task'] as Map<String, dynamic>;
        int taskTakenId = item['task_taken_id'];
        TaskModel task = TaskModel(
          title: taskData['task_title'] as String?,
          clientId: null,
          specialization: null,
          description: null,
          location: null,
          period: null,
          duration: null,
          urgency: taskData['urgent'] as String?,
          // Check if this field exists in your API
          status: null,
          contactPrice: null,
          remarks: null,
          taskBeginDate: null,

          id: taskData[
              'task_id'], // Use taskTakenId here if it's meant to be the task's ID

          //id: taskData['task_id'], // Use taskTakenId here if it's meant to be the task's ID
        );

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

        // Parse tasker and its user
        Map<String, dynamic> taskerData = item['tasker'] != null
            ? item['tasker'] as Map<String, dynamic>
            : {};
        Map<String, dynamic> taskerUserData =
            taskerData['user'] as Map<String, dynamic>;
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
          group: false,
          user: taskerUser,
        );

        // Create TaskAssignment with the correct taskTakenId
        TaskAssignment assignment = TaskAssignment(
          client: client,
          tasker: tasker,
          task: task,
          taskTakenId: taskTakenId, // Use the root-level task_taken_id
        );
        debugPrint(assignment.toString()); // Verify the full object
        return assignment;
      }).toList();
      return taskAssignments;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(assignedTasks['error'] ??
                "Something Went Wrong while Retrieving Your Tasks.")),
      );
      return null;
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
}
