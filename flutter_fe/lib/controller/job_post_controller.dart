import 'package:flutter/material.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'dart:math' as math;

class JobPostController {
  final JobPostService jobPostService = JobPostService();
  final userId = GetStorage().read('user_id');
  final clientServices = ClientServices();
  List<MapEntry<int, String>> specialization = [MapEntry(0, 'All')];

  Future<List<TaskModel>> fetchAllJobs() async {
    try {
      final fetchedTasks = await jobPostService.fetchAllJobs();
      final fetchedMyData = await clientServices.fetchMyDataTasker(userId);
      final fetchedSpecializations = await jobPostService.getSpecializations();

      final specializationMap = {
        0: 'All',
        for (var spec
            in fetchedSpecializations.where((spec) => spec.id != null))
          spec.id!: spec.specialization,
      };

      debugPrint("My data this is my data: $fetchedMyData");
      debugPrint("Specialization Map: $specializationMap");
      debugPrint("This is fetched task, $fetchedTasks");

      if (fetchedMyData?.user == null ||
          fetchedMyData?.user?.userPreferences == null ||
          fetchedMyData?.user?.userPreferences?.isEmpty == true) {
        debugPrint("No tasker preferences found");
        return fetchedTasks;
      }

      final taskerPreferences = fetchedMyData!.user!.userPreferences!.first;

      final desiredSpecializationIds = <int>[];
      if (taskerPreferences.specialization.isNotEmpty) {
        debugPrint("Raw specialization: ${taskerPreferences.specialization}");

        for (final item in taskerPreferences.specialization) {
          try {
            if (item.startsWith('[') && item.endsWith(']')) {
              final List<dynamic> ids = jsonDecode(item);
              for (final idStr in ids) {
                if (idStr != null && idStr.toString().trim().isNotEmpty) {
                  final id = int.tryParse(idStr.toString().trim());
                  if (id != null) {
                    desiredSpecializationIds.add(id);
                  }
                }
              }
            } else {
              final id = int.tryParse(item.trim());
              if (id != null) {
                desiredSpecializationIds.add(id);
              }
            }
          } catch (e) {
            debugPrint("Error parsing specialization item: $item, error: $e");
          }
        }
      } else {
        debugPrint("Specialization list is empty");
      }

      final includesAllSpecializations = desiredSpecializationIds.contains(0);

      final desiredSpecializationNames = includesAllSpecializations
          ? <String>[]
          : desiredSpecializationIds
              .map((id) => specializationMap[id])
              .where((name) => name != null)
              .cast<String>()
              .toList();

      debugPrint("Desired specialization IDs: $desiredSpecializationIds");
      debugPrint("Desired specialization names: $desiredSpecializationNames");
      debugPrint("Includes all specializations: $includesAllSpecializations");

      final taskerLat = taskerPreferences.address.latitude ?? 0.0;
      final taskerLon = taskerPreferences.address.longitude ?? 0.0;
      final maxDistance = taskerPreferences.distance;

      double degToRad(double deg) => deg * (math.pi / 180);

      double calculateDistance(
          double lat1, double lon1, double lat2, double lon2) {
        const R = 6371;
        final dLat = degToRad(lat2 - lat1);
        final dLon = degToRad(lon2 - lon1);
        final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(degToRad(lat1)) *
                math.cos(degToRad(lat2)) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);
        final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        return R * c;
      }

      List<TaskModel> matchedJobs = [];
      List<TaskModel> unmatchedJobs = [];
      final jobScores = <TaskModel, Map<String, dynamic>>{};

      for (var job in fetchedTasks) {
        bool matchesSpecialization = false;
        bool matchesDistance = false;
        double distance = double.infinity;
        int score = 0;

        if (includesAllSpecializations ||
            desiredSpecializationNames.isEmpty ||
            desiredSpecializationNames.contains(job.specialization)) {
          matchesSpecialization = true;
          score += 2;
        }

        final jobLat = job.address?.latitude ?? 0.0;
        final jobLon = job.address?.longitude ?? 0.0;

        if (taskerLat != 0.0 &&
            taskerLon != 0.0 &&
            jobLat != 0.0 &&
            jobLon != 0.0) {
          distance = calculateDistance(taskerLat, taskerLon, jobLat, jobLon);
          if (distance <= maxDistance) {
            matchesDistance = true;
            score += 1;
          }
        } else {
          matchesDistance = true;
          score += 1;
        }

        if (matchesSpecialization && matchesDistance) {
          matchedJobs.add(job);
        } else {
          unmatchedJobs.add(job);
        }

        jobScores[job] = {'score': score, 'distance': distance};
      }

      List<TaskModel> result = [];
      if (taskerPreferences.limit) {
        result = [...matchedJobs, ...unmatchedJobs];
        result.sort((a, b) {
          final scoreA = jobScores[a]!['score'] as int;
          final scoreB = jobScores[b]!['score'] as int;
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }
          final distA = jobScores[a]!['distance'] as double;
          final distB = jobScores[b]!['distance'] as double;
          return distA.compareTo(distB);
        });
      } else {
        result = matchedJobs;
      }

      debugPrint("Matched jobs: ${matchedJobs.length}");
      debugPrint("Unmatched jobs: ${unmatchedJobs.length}");
      debugPrint("Returning ${result.length} jobs");

      return result;
    } catch (e, stackTrace) {
      debugPrint("Error while fetching jobs for tasker: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }
}
