import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/task_model.dart';

class TaskDetailsService {
  Future<TaskModel?> fetchTaskDetails(int taskId) async {
    try {
      final url = Uri.parse(
          "http://192.168.254.113:5000/connect/displayLikedJob/$taskId");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('tasks') && jsonData['tasks'].isNotEmpty) {
          return TaskModel.fromJson(jsonData['tasks'][0]);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Exception in fetchTaskDetails: $e");
      return null;
    }
  }
}
