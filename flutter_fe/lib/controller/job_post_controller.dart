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

      debugPrint(
          "Fetched user data: ${fetchedMyData?.user?.email ?? 'No user data'}");
      debugPrint("Specialization map: $specializationMap");
      debugPrint("Total tasks fetched: ${fetchedTasks.length}");

      if (fetchedMyData?.user == null ||
          fetchedMyData?.user?.userPreferences == null ||
          fetchedMyData?.user?.userPreferences?.isEmpty == true) {
        debugPrint("No tasker preferences found, returning all tasks");
        return fetchedTasks;
      }

      final taskerPreferences = fetchedMyData!.user!.userPreferences!.first;

      final desiredSpecializationIds = <int>[];
      if (taskerPreferences.specialization.isNotEmpty) {
        for (final item in taskerPreferences.specialization) {
          try {
            final decoded = item.startsWith('[') && item.endsWith(']')
                ? jsonDecode(item) as List<dynamic>
                : [item];
            for (final idStr in decoded) {
              final id = int.tryParse(idStr.toString().trim());
              if (id != null) {
                desiredSpecializationIds.add(id);
              }
            }
          } catch (e) {
            debugPrint("Error parsing specialization '$item': $e");
          }
        }
      }

      final includesAllSpecializations = desiredSpecializationIds.contains(0);
      final desiredSpecializationNames = includesAllSpecializations
          ? <String>[]
          : desiredSpecializationIds
              .map((id) => specializationMap[id])
              .whereType<String>()
              .toList();

      debugPrint("Desired specialization IDs: $desiredSpecializationIds");
      debugPrint("Desired specialization names: $desiredSpecializationNames");

      final taskerLat = taskerPreferences.address.latitude ?? 0.0;
      final taskerLon = taskerPreferences.address.longitude ?? 0.0;
      final maxDistance = taskerPreferences.distance ?? 100.0;
      final ageStart = taskerPreferences.ageStart ?? 18;
      final ageEnd = taskerPreferences.ageEnd ?? 100;

      double degToRad(double deg) => deg * (math.pi / 180);

      double calculateDistance(
          double lat1, double lon1, double lat2, double lon2) {
        const R = 6371; // Earth's radius in km
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
        int score = 0;
        bool matchesSpecialization = false;
        bool matchesDistance = false;
        double distance = double.infinity;

        final jobSpecializationId = job.specializationId;
        if (includesAllSpecializations ||
            desiredSpecializationIds.contains(jobSpecializationId) ||
            (job.relatedSpecializationsIds != null &&
                job.relatedSpecializationsIds!
                    .any((id) => desiredSpecializationIds.contains(id)))) {
          matchesSpecialization = true;
          score += 3;
        }

        final jobLat = job.address?.latitude;
        final jobLon = job.address?.longitude;
        if (jobLat != null &&
            jobLon != null &&
            taskerLat != 0.0 &&
            taskerLon != 0.0) {
          distance = calculateDistance(taskerLat, taskerLon, jobLat, jobLon);
          if (distance <= maxDistance) {
            matchesDistance = true;
            score += 2;
          }
        } else {
          matchesDistance = true;
          score += 1;
        }

        // Optional: Add age-based filtering (if tasks include client age info)
        // Note: The provided data doesn't include client age, so this is a placeholder
        // If client age is available in TaskModel, you could add:
        /*
        final clientAge = job.client?.birthdate != null
            ? DateTime.now().year - job.client!.birthdate!.year
            : null;
        bool matchesAge = clientAge != null &&
            clientAge >= ageStart &&
            clientAge <= ageEnd;
        if (matchesAge) score += 1;
        */

        // Optional: Boost score for urgent tasks
        if (job.urgency == 'Urgent') {
          score += 1;
        }

        jobScores[job] = {'score': score, 'distance': distance};
        if (matchesSpecialization && matchesDistance) {
          matchedJobs.add(job);
        } else {
          unmatchedJobs.add(job);
        }
      }

      List<TaskModel> result = [];
      if (taskerPreferences.limit == true) {
        // Include all jobs, sorted by score and distance
        result = [...matchedJobs, ...unmatchedJobs];
        result.sort((a, b) {
          final scoreA = jobScores[a]!['score'] as int;
          final scoreB = jobScores[b]!['score'] as int;
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA); // Higher score first
          }
          final distA = jobScores[a]!['distance'] as double;
          final distB = jobScores[b]!['distance'] as double;
          return distA.compareTo(distB); // Closer distance first
        });
      } else {
        result = matchedJobs;
      }

      debugPrint("Matched jobs: ${matchedJobs.length}");
      debugPrint("Unmatched jobs: ${unmatchedJobs.length}");
      debugPrint("Returning ${result.length} jobs");

      return result;
    } catch (e, stackTrace) {
      debugPrint("Error fetching jobs: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }
}
