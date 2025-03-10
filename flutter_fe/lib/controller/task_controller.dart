import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
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
        id: 0,
        title: jobTitleController.text.trim(),
        specialization: specialization,
        description: jobDescriptionController.text.trim(),
        location: jobLocationController.text.trim(),
        duration: int.tryParse(jobTimeController.text),
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

  Future<Map<String, dynamic>> assignTask(int userId, int taskId) async {
    return await _jobPostService.assignTask(userId, taskId);
  }
}
