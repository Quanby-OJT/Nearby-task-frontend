import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/milestone_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MilestoneService {
  final GetStorage storage = GetStorage();

  String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://localhost:8000';
  }

  Map<String, String> get headers {
    final token = storage.read('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all milestones for a task
  Future<List<MilestoneModel>> getTaskMilestones(int taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$taskId/milestones'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => MilestoneModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch milestones');
      }
    } catch (e) {
      debugPrint('Error fetching milestones: $e');
      return [];
    }
  }

  // Create a new milestone
  Future<Map<String, dynamic>> createMilestone(MilestoneModel milestone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks/${milestone.taskId}/milestones'),
        headers: headers,
        body: json.encode(milestone.toJson()),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'milestone':
              MilestoneModel.fromJson(json.decode(response.body)['data']),
        };
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to create milestone',
        };
      }
    } catch (e) {
      debugPrint('Error creating milestone: $e');
      return {
        'success': false,
        'error': 'Network error occurred',
      };
    }
  }

  // Update a milestone
  Future<Map<String, dynamic>> updateMilestone(MilestoneModel milestone) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/milestones/${milestone.id}'),
        headers: headers,
        body: json.encode(milestone.toJson()),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'milestone':
              MilestoneModel.fromJson(json.decode(response.body)['data']),
        };
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to update milestone',
        };
      }
    } catch (e) {
      debugPrint('Error updating milestone: $e');
      return {
        'success': false,
        'error': 'Network error occurred',
      };
    }
  }

  // Delete a milestone
  Future<Map<String, dynamic>> deleteMilestone(int milestoneId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/milestones/$milestoneId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to delete milestone',
        };
      }
    } catch (e) {
      debugPrint('Error deleting milestone: $e');
      return {
        'success': false,
        'error': 'Network error occurred',
      };
    }
  }

  // Update milestone status
  Future<Map<String, dynamic>> updateMilestoneStatus(
      int milestoneId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/milestones/$milestoneId/status'),
        headers: headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'milestone':
              MilestoneModel.fromJson(json.decode(response.body)['data']),
        };
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to update milestone status',
        };
      }
    } catch (e) {
      debugPrint('Error updating milestone status: $e');
      return {
        'success': false,
        'error': 'Network error occurred',
      };
    }
  }

  // Reorder milestones
  Future<Map<String, dynamic>> reorderMilestones(
      int taskId, List<int> milestoneIds) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/tasks/$taskId/milestones/reorder'),
        headers: headers,
        body: json.encode({'milestone_ids': milestoneIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to reorder milestones',
        };
      }
    } catch (e) {
      debugPrint('Error reordering milestones: $e');
      return {
        'success': false,
        'error': 'Network error occurred',
      };
    }
  }
}
