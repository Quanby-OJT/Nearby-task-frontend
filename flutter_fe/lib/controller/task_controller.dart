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

  Future<Map<String, dynamic>> postJob(
      String? specialization, bool urgency, String? period) async {
    try {
      int userId = storage.read('user_id');
      print('Submitting data...'); // Debug print
      final task = TaskModel(
        id: 0, // Set to 0 for new posts
        clientId: userId,
        title: jobTitleController.text.trim(),
        specialization: specialization,
        description: jobDescriptionController.text.trim(),
        location: jobLocationController.text.trim(),
        duration: int.tryParse(jobTimeController.text.trim()),
        period: period,
        urgency: urgency,
        contactPrice: double.tryParse(contactPriceController.text.trim()),
        remarks: jobRemarksController.text.trim(),
        taskBeginDate: jobTaskBeginDateController.text.trim(),
      );

      print('Task data: ${task.toJson()}'); // Debug print
      return await _jobPostService.postJob(task, userId);
    } catch (e, stackTrace) {
      print('Error in postJob: $e'); // Debug print
      debugPrint(stackTrace.toString());
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<List<TaskModel>?> getJobsforClient(
      BuildContext context, int clientId) async {
    final clientTask = await _jobPostService.fetchJobsForClient(clientId);
    debugPrint(clientTask.toString());

    if (clientTask.containsKey('tasks')) {
      List<dynamic> tasksList =
          clientTask['tasks']; // Extract the list from the map

      List<TaskModel> tasks = tasksList
          .map((task) => TaskModel.fromJson(task))
          .toList(); // Convert list to TaskModel list

      return tasks;
    }

    // Show error message if tasks are not found
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(clientTask['error'] ??
            "Something Went Wrong while Retrieving Your Tasks.")));

    return null;
  }

  Future<String> assignTask(int? taskId, int? clientId, int? taskerId) async {
    debugPrint("Assigning task...");
    final assignedTask =
        await _jobPostService.assignTask(taskId, clientId, taskerId);

    if (assignedTask.containsKey('message')) {
      return assignedTask['message'].toString();
    } else {
      return assignedTask['error'].toString();
    }
  }

  Future<List<TaskAssignment>?> getAllAssignedTasks(
      BuildContext context, int userId) async {
    final assignedTasks = await TaskDetailsService().getAllTakenTasks();
    debugPrint(assignedTasks.toString());

    if (assignedTasks.containsKey('data') && assignedTasks['data'] != null) {
      List<dynamic> dataList = assignedTasks['data'] as List<dynamic>;

      List<TaskAssignment> taskAssignments = dataList.map((item) {
        // Get task_taken_id from each item
        int? taskId =
            item['task_taken_id'] as int?; // Directly access task_taken_id
        //debugPrint("Task Id: $taskId");

        // Parse tasks
        Map<String, dynamic> taskData = item['tasks'] as Map<String, dynamic>;
        TaskModel task = TaskModel(
          title: taskData['task_title'] as String?,
          // Provide default or null values for required fields not in the response
          clientId: null,
          specialization: null,
          description: null,
          location: null,
          period: null,
          duration: null,
          urgency: taskData['urgent'] as bool?,
          status: null,
          contactPrice: null,
          remarks: null,
          taskBeginDate: null,
          id: taskId, // You could use taskId here if needed
        );

        // Parse client and its user
        Map<String, dynamic> clientData =
            item['clients'] as Map<String, dynamic>;
        Map<String, dynamic> clientUserData =
            clientData['user'] as Map<String, dynamic>;
        UserModel clientUser = UserModel(
          firstName: clientUserData['first_name'] as String? ?? '',
          middleName: clientUserData['middle_name'] as String? ?? '',
          lastName: clientUserData['last_name'] as String? ?? '',
          email: '', // Required field, provide default
          role: '', // Required field, provide default
          accStatus: '', // Required field, provide default
        );
        ClientModel client = ClientModel(
          preferences: '', // Required field, provide default
          clientAddress: '', // Required field, provide default
          user: clientUser,
        );

        // Parse tasker and its user
        Map<String, dynamic> taskerData =
            item['tasker'] as Map<String, dynamic>;
        Map<String, dynamic> taskerUserData =
            taskerData['user'] as Map<String, dynamic>;
        UserModel taskerUser = UserModel(
          firstName: taskerUserData['first_name'] as String? ?? '',
          middleName: taskerUserData['middle_name'] as String? ?? '',
          lastName: taskerUserData['last_name'] as String? ?? '',
          email: '', // Required field, provide default
          role: '', // Required field, provide default
          accStatus: '', // Required field, provide default
        );
        TaskerModel tasker = TaskerModel(
          bio: '', // Required field, provide default
          specialization: '', // Required field, provide default
          skills: '', // Required field, provide default
          taskerAddress: '', // Required field, provide default
          user: taskerUser,
        );

        return TaskAssignment(client: client, tasker: tasker, task: task);
      }).toList();

      return taskAssignments;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(assignedTasks['error'] ??
              "Something Went Wrong while Retrieving Your Tasks."),
        ),
      );
      return null;
    }
  }
}
