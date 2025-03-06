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
  final jobDaysController = TextEditingController();
  final jobUrgencyController = TextEditingController();
  final contactPriceController = TextEditingController();
  final jobRemarksController = TextEditingController();
  final jobTaskBeginDateController = TextEditingController();
  final contactpriceController = TextEditingController();
  final storage = GetStorage();

  Future<Map<String, dynamic>> postJob() async {
    try {
      int userId = storage.read('user_id');
      print('Submitting data:'); // Debug print
      final task = TaskModel(
        id: 0, // Set to 0 for new posts
        title: jobTitleController.text.trim(),
        specialization: jobSpecializationController.text.trim(),
        description: jobDescriptionController.text.trim(),
        location: jobLocationController.text.trim(),
        duration: jobDurationController.text.trim(),
        numberOfDays: int.tryParse(jobDaysController.text.trim()) ?? 0,
        urgency: jobUrgencyController.text.trim(),
        contactPrice: int.tryParse(contactPriceController.text.trim()) ?? 0,
        remarks: jobRemarksController.text.trim(),
        taskBeginDate: jobTaskBeginDateController.text.trim(),
      );

      print('Task data: ${task.toJson()}'); // Debug print
      return await _jobPostService.postJob(task, userId);
    } catch (e) {
      print('Error in postJob: $e'); // Debug print
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
