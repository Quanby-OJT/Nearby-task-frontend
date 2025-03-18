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

  Future<Map<String, dynamic>> postJob(String? specialization, String? urgency, String? period, String? workType) async {
    try {
      int userId = storage.read('user_id');
      print('Submitting data...');
      final task = TaskModel(
        id: 0,
        clientId: userId,
        title: jobTitleController.text.trim(),
        specialization: specialization,
        description: jobDescriptionController.text.trim(),
        location: jobLocationController.text.trim(),
        duration: jobTimeController.text,
        period: period,
        urgency: urgency,
        contactPrice: int.tryParse(contactPriceController.text.trim()) ?? 0,
        remarks: jobRemarksController.text.trim(),
        taskBeginDate: jobTaskBeginDateController.text.trim(),
        workType: workType,
      );

      print('Task data: ${task.toJson()}');
      return await _jobPostService.postJob(task, userId);
    } catch (e, stackTrace) {
      print('Error in postJob: $e');
      debugPrint(stackTrace.toString());
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<List<TaskModel>?> getJobsforClient(
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
    return null;
  }

  Future<String> assignTask(int? taskId, int? clientId, int? taskerId) async {
    debugPrint("Assigning task...");
    final assignedTask =
        await _jobPostService.assignTask(taskId, clientId, taskerId);
    return assignedTask.containsKey('message')
        ? assignedTask['message'].toString()
        : assignedTask['error'].toString();
  }

  //All Messages to client/tasker
  Future<List<TaskAssignment>?> getAllAssignedTasks(BuildContext context, int userId) async {
    final assignedTasks = await TaskDetailsService().getAllTakenTasks();
    debugPrint(assignedTasks.toString());

    if (assignedTasks.containsKey('data') && assignedTasks['data'] != null) {
      List<dynamic> dataList = assignedTasks['data'] as List<dynamic>;
      List<TaskAssignment> taskAssignments = dataList.map((item) {
        // Get task_taken_id from the root level of item
        int? taskTakenId = item['task_taken_id'] as int?; // Correct key
        debugPrint("Task Taken ID: $taskTakenId"); // Verify the value

        // Parse tasks from post_task
        Map<String, dynamic> taskData = item['post_task'] as Map<String, dynamic>;
        TaskModel task = TaskModel(
          title: taskData['task_title'] as String?,
          clientId: null,
          specialization: null,
          description: null,
          location: null,
          period: null,
          duration: null,
          urgency: taskData['urgent'] as String?, // Check if this field exists in your API
          status: null,
          contactPrice: null,
          remarks: null,
          taskBeginDate: null,
          id: taskTakenId, // Use taskTakenId here if it’s meant to be the task’s ID
        );

        // Parse client and its user
        Map<String, dynamic> clientData = item['clients'] != null ? item['clients'] as Map<String, dynamic> : {};
        Map<String, dynamic> clientUserData = clientData['user'] as Map<String, dynamic>;
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
        Map<String, dynamic> taskerData = item['tasker'] != null ? item['tasker'] as Map<String, dynamic> : {};
        Map<String, dynamic> taskerUserData = taskerData['user'] as Map<String, dynamic>;
        UserModel taskerUser = UserModel(
          firstName: taskerUserData['first_name'] as String? ?? '',
          middleName: taskerUserData['middle_name'] as String? ?? '',
          lastName: taskerUserData['last_name'] as String? ?? '',
          email: '',
          role: '',
          accStatus: '',
        );
        TaskerModel tasker = TaskerModel(
          bio: '',
          specialization: '',
          skills: '',
          taskerAddress: '',
          availability: false,
          wage: 0.0,
          payPeriod: '',
          birthDate: DateTime.now(),
          phoneNumber: '',
          gender: '',
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
}
