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
      String? specialization, String? urgency, String? period) async {
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
        duration: jobTimeController.text,
        period: period,
        urgency: urgency,
        contactPrice: int.tryParse(contactPriceController.text.trim()) ?? 0,
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

  Future<String> assignTask(int? taskerId, int? clientId, int? taskId) async {
    final assignedTask =
        await _jobPostService.assignTask(taskId, taskerId, clientId);

    if (assignedTask.containsKey('message')) {
      return assignedTask['message'].toString();
    } else {
      return assignedTask['error'].toString();
    }
  }

  Future<TaskAssignment?> getAllAssignedTasks(
      BuildContext context, int userId) async {
    final assignedTasks = await TaskDetailsService().getAllTakenTasks();

    if (assignedTasks.containsKey('tasks')) {
      TaskModel tasks = assignedTasks['tasks'] as TaskModel;
      ClientModel client = assignedTasks['clients'] as ClientModel;
      TaskerModel tasker = assignedTasks['taskers'] as TaskerModel;
      UserModel user = assignedTasks['users'] as UserModel;
      return TaskAssignment(client: client, tasker: tasker, task: tasks);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(assignedTasks['error'] ??
              "Something Went Wrong while Retrieving Your Tasks.")));
    }

    return null;
  }

  // Future<Map<String, dynamic>> getLikedJobs(int taskerId) async {
  //
  // }
}
