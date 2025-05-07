import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';

class JobPostController {
  final JobPostService jobPostService = JobPostService();

  Future<List<TaskModel>> fetchAllJobs() async {
    try {
      final fetchedTasks = await jobPostService.fetchAllJobs();

      debugPrint("Fetched Tasks: ${fetchedTasks.length}");
      return fetchedTasks;
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
      return [];
    }
  }
}
