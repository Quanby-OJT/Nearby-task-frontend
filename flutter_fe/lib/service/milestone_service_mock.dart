import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/milestone_model.dart';
import 'package:get_storage/get_storage.dart';

class MilestoneServiceMock {
  final GetStorage storage = GetStorage();

  // Mock data storage key
  String _getStorageKey(int taskId) => 'milestones_task_$taskId';

  // Get all milestones for a task
  Future<List<MilestoneModel>> getTaskMilestones(int taskId) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 500));

      final storageKey = _getStorageKey(taskId);
      final storedData = storage.read(storageKey);

      if (storedData == null) {
        return [];
      }

      final List<dynamic> data = json.decode(storedData);
      return data.map((json) => MilestoneModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching milestones: $e');
      return [];
    }
  }

  // Create a new milestone
  Future<Map<String, dynamic>> createMilestone(MilestoneModel milestone) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 800));

      final storageKey = _getStorageKey(milestone.taskId);
      final existingMilestones = await getTaskMilestones(milestone.taskId);

      // Generate a mock ID
      final newId = DateTime.now().millisecondsSinceEpoch;

      final newMilestone = milestone.copyWith(
        id: newId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      existingMilestones.add(newMilestone);

      // Store updated list
      final jsonList = existingMilestones.map((m) => m.toJson()).toList();
      storage.write(storageKey, json.encode(jsonList));

      return {
        'success': true,
        'milestone': newMilestone,
      };
    } catch (e) {
      debugPrint('Error creating milestone: $e');
      return {
        'success': false,
        'error': 'Failed to create milestone',
      };
    }
  }

  // Update a milestone
  Future<Map<String, dynamic>> updateMilestone(MilestoneModel milestone) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 600));

      final storageKey = _getStorageKey(milestone.taskId);
      final existingMilestones = await getTaskMilestones(milestone.taskId);

      final index = existingMilestones.indexWhere((m) => m.id == milestone.id);
      if (index == -1) {
        return {
          'success': false,
          'error': 'Milestone not found',
        };
      }

      final updatedMilestone = milestone.copyWith(updatedAt: DateTime.now());
      existingMilestones[index] = updatedMilestone;

      // Store updated list
      final jsonList = existingMilestones.map((m) => m.toJson()).toList();
      storage.write(storageKey, json.encode(jsonList));

      return {
        'success': true,
        'milestone': updatedMilestone,
      };
    } catch (e) {
      debugPrint('Error updating milestone: $e');
      return {
        'success': false,
        'error': 'Failed to update milestone',
      };
    }
  }

  // Delete a milestone
  Future<Map<String, dynamic>> deleteMilestone(int milestoneId) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 400));

      // Find which task this milestone belongs to
      final keys = storage
          .getKeys()
          .where((key) => key.toString().startsWith('milestones_task_'));

      for (String key in keys) {
        final storedData = storage.read(key);
        if (storedData != null) {
          final List<dynamic> data = json.decode(storedData);
          final milestones =
              data.map((json) => MilestoneModel.fromJson(json)).toList();

          final index = milestones.indexWhere((m) => m.id == milestoneId);
          if (index != -1) {
            milestones.removeAt(index);

            // Store updated list
            final jsonList = milestones.map((m) => m.toJson()).toList();
            storage.write(key, json.encode(jsonList));

            return {'success': true};
          }
        }
      }

      return {
        'success': false,
        'error': 'Milestone not found',
      };
    } catch (e) {
      debugPrint('Error deleting milestone: $e');
      return {
        'success': false,
        'error': 'Failed to delete milestone',
      };
    }
  }

  // Update milestone status
  Future<Map<String, dynamic>> updateMilestoneStatus(
      int milestoneId, String status) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 500));

      // Find which task this milestone belongs to
      final keys = storage
          .getKeys()
          .where((key) => key.toString().startsWith('milestones_task_'));

      for (String key in keys) {
        final storedData = storage.read(key);
        if (storedData != null) {
          final List<dynamic> data = json.decode(storedData);
          final milestones =
              data.map((json) => MilestoneModel.fromJson(json)).toList();

          final index = milestones.indexWhere((m) => m.id == milestoneId);
          if (index != -1) {
            final updatedMilestone = milestones[index].copyWith(
              status: status,
              updatedAt: DateTime.now(),
              completedAt: status == 'completed' ? DateTime.now() : null,
            );
            milestones[index] = updatedMilestone;

            // Store updated list
            final jsonList = milestones.map((m) => m.toJson()).toList();
            storage.write(key, json.encode(jsonList));

            return {
              'success': true,
              'milestone': updatedMilestone,
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'Milestone not found',
      };
    } catch (e) {
      debugPrint('Error updating milestone status: $e');
      return {
        'success': false,
        'error': 'Failed to update milestone status',
      };
    }
  }

  // Reorder milestones
  Future<Map<String, dynamic>> reorderMilestones(
      int taskId, List<int> milestoneIds) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 600));

      final storageKey = _getStorageKey(taskId);
      final existingMilestones = await getTaskMilestones(taskId);

      // Reorder milestones based on the provided order
      final reorderedMilestones = <MilestoneModel>[];
      for (int i = 0; i < milestoneIds.length; i++) {
        final milestone =
            existingMilestones.firstWhere((m) => m.id == milestoneIds[i]);
        reorderedMilestones.add(milestone.copyWith(order: i + 1));
      }

      // Store reordered list
      final jsonList = reorderedMilestones.map((m) => m.toJson()).toList();
      storage.write(storageKey, json.encode(jsonList));

      return {'success': true};
    } catch (e) {
      debugPrint('Error reordering milestones: $e');
      return {
        'success': false,
        'error': 'Failed to reorder milestones',
      };
    }
  }

  // Helper method to clear all mock data
  Future<void> clearAllMockData() async {
    final keys = storage
        .getKeys()
        .where((key) => key.toString().startsWith('milestones_task_'));
    for (String key in keys) {
      storage.remove(key);
    }
  }

  // Helper method to seed sample data for testing
  Future<void> seedSampleData(int taskId, double taskAmount) async {
    final sampleMilestones = [
      MilestoneModel(
        id: 1001,
        taskId: taskId,
        title: 'Initial Planning',
        description: 'Create project plan and requirements document',
        amount: taskAmount * 0.2,
        dueDate: DateTime.now().add(Duration(days: 7)),
        status: 'completed',
        order: 1,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
        completedAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      MilestoneModel(
        id: 1002,
        taskId: taskId,
        title: 'Development Phase 1',
        description: 'Implement core functionality and basic UI',
        amount: taskAmount * 0.4,
        dueDate: DateTime.now().add(Duration(days: 14)),
        status: 'in_progress',
        order: 2,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      MilestoneModel(
        id: 1003,
        taskId: taskId,
        title: 'Testing & QA',
        description: 'Comprehensive testing and quality assurance',
        amount: taskAmount * 0.2,
        dueDate: DateTime.now().add(Duration(days: 21)),
        status: 'pending',
        order: 3,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
      ),
      MilestoneModel(
        id: 1004,
        taskId: taskId,
        title: 'Final Delivery',
        description: 'Final review, documentation, and project handover',
        amount: taskAmount * 0.15,
        dueDate: DateTime.now().add(Duration(days: 28)),
        status: 'pending',
        order: 4,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
      ),
      MilestoneModel(
        id: 1005,
        taskId: taskId,
        title: 'Client Feedback',
        description: 'Gather and incorporate client feedback',
        amount: null, // No amount specified for this milestone
        dueDate: DateTime.now().add(Duration(days: 25)),
        status: 'pending',
        order: 5,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(days: 5)),
      ),
    ];

    final storageKey = _getStorageKey(taskId);
    final jsonList = sampleMilestones.map((m) => m.toJson()).toList();
    storage.write(storageKey, json.encode(jsonList));

    debugPrint('Sample milestone data seeded for task $taskId');
  }
}
