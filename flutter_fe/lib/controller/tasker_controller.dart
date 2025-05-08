import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math' as math;
import 'dart:convert';

class TaskerController {
  final userId = GetStorage().read('user_id');
  final clientServices = ClientServices();
  final JobPostService jobPostService = JobPostService();
  List<MapEntry<int, String>> specialization = [MapEntry(0, 'All')];

  Future<List<TaskerModel>> getAllTaskers() async {
    try {
      final fetchedTaskers =
          await clientServices.fetchAllFilteredTasker(userId);
      final fetchedMyData = await clientServices.fetchMyData(userId);
      final fetchedSpecializations = await jobPostService.getSpecializations();

      final specializationMap = {
        0: 'All',
        for (var spec
            in fetchedSpecializations.where((spec) => spec.id != null))
          spec.id!: spec.specialization,
      };

      debugPrint("My data: $fetchedMyData");
      debugPrint("Fetched Taskers: ${fetchedTaskers.length} taskers");
      for (var tasker in fetchedTaskers) {
        debugPrint(
            "Tasker: ${tasker.user?.firstName}, Specialization: ${tasker.specialization}");
      }
      debugPrint("Specialization Map: $specializationMap");

      if (fetchedMyData?.user == null ||
          fetchedMyData?.user?.userPreferences == null ||
          fetchedMyData?.user?.userPreferences?.isEmpty == true) {
        debugPrint("No client preferences found, returning all taskers");
        return fetchedTaskers;
      }

      final clientPreferences = fetchedMyData!.user!.userPreferences!.first;

      // Parse specialization IDs and map to names
      final desiredSpecializationIds = <int>[];
      final desiredSpecializationNames = <String>[];

      if (clientPreferences.specialization.isNotEmpty) {
        debugPrint("Raw specialization: ${clientPreferences.specialization}");

        for (final item in clientPreferences.specialization) {
          try {
            if (item.startsWith('[') && item.endsWith(']')) {
              final List<dynamic> ids = jsonDecode(item);
              for (final idStr in ids) {
                if (idStr != null && idStr.toString().trim().isNotEmpty) {
                  final id = int.tryParse(idStr.toString().trim());
                  if (id != null && specializationMap.containsKey(id)) {
                    desiredSpecializationIds.add(id);
                    if (id != 0) {
                      desiredSpecializationNames.add(specializationMap[id]!);
                    }
                  }
                }
              }
            } else {
              final id = int.tryParse(item.trim());
              if (id != null && specializationMap.containsKey(id)) {
                desiredSpecializationIds.add(id);
                if (id != 0) {
                  desiredSpecializationNames.add(specializationMap[id]!);
                }
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

      debugPrint("Desired specialization IDs: $desiredSpecializationIds");
      debugPrint("Desired specialization names: $desiredSpecializationNames");
      debugPrint("Includes all specializations: $includesAllSpecializations");

      final clientLat = clientPreferences.address.latitude ?? 0.0;
      final clientLon = clientPreferences.address.longitude ?? 0.0;
      final maxDistance = clientPreferences.distance;
      final ageStart = clientPreferences.ageStart;
      final ageEnd = clientPreferences.ageEnd;
      final limit = clientPreferences.limit;

      debugPrint(
          "Client Preferences - Limit: $limit, Max Distance: $maxDistance, "
          "Age Range: $ageStart-$ageEnd");

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

      int calculateAge(DateTime birthdate) {
        final now = DateTime.now();
        int age = now.year - birthdate.year;
        if (now.month < birthdate.month ||
            (now.month == birthdate.month && now.day < birthdate.day)) {
          age--;
        }
        return age;
      }

      List<TaskerModel> matchedTaskers = [];
      List<TaskerModel> unmatchedTaskers = [];
      final taskerScores = <TaskerModel, Map<String, dynamic>>{};

      for (var tasker in fetchedTaskers) {
        bool matchesSpecialization = false;
        bool matchesDistance = false;
        bool matchesAge = false;
        double distance = double.infinity;
        int score = 0;

        if (includesAllSpecializations ||
            desiredSpecializationNames.isEmpty ||
            desiredSpecializationNames.contains(tasker.specialization)) {
          matchesSpecialization = true;
          score += 2;
        }

        final taskerLat = tasker.user?.userPreferences?.isNotEmpty == true
            ? tasker.user!.userPreferences!.first.address.latitude ?? 0.0
            : 0.0;
        final taskerLon = tasker.user?.userPreferences?.isNotEmpty == true
            ? tasker.user!.userPreferences!.first.address.longitude ?? 0.0
            : 0.0;

        if (clientLat != 0.0 &&
            clientLon != 0.0 &&
            taskerLat != 0.0 &&
            taskerLon != 0.0) {
          distance =
              calculateDistance(clientLat, clientLon, taskerLat, taskerLon);
          if (distance <= maxDistance) {
            matchesDistance = true;
            score += 1;
          }
        } else {
          matchesDistance = true;
          score += 1;
        }

        if (tasker.user?.birthdate != null) {
          try {
            final birthdate = DateTime.parse(tasker.user!.birthdate!);
            final age = calculateAge(birthdate);
            if (age >= ageStart && age <= ageEnd) {
              matchesAge = true;
              score += 1;
            }
          } catch (e) {
            debugPrint("Error parsing birthdate: ${tasker.user!.birthdate}");
            matchesAge = true;
            score += 1;
          }
        } else {
          matchesAge = true;
          score += 1;
        }

        debugPrint(
            "Tasker: ${tasker.user?.firstName}, Specialization: ${tasker.specialization}, "
            "Matches Specialization: $matchesSpecialization, Matches Distance: $matchesDistance, "
            "Matches Age: $matchesAge, Distance: $distance, Score: $score");

        if (matchesSpecialization && matchesDistance && matchesAge) {
          matchedTaskers.add(tasker);
        } else {
          unmatchedTaskers.add(tasker);
        }

        taskerScores[tasker] = {'score': score, 'distance': distance};
      }

      List<TaskerModel> result = [];
      if (limit) {
        result = [...matchedTaskers, ...unmatchedTaskers];
        result.sort((a, b) {
          final scoreA = taskerScores[a]!['score'] as int;
          final scoreB = taskerScores[b]!['score'] as int;
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }
          final distA = taskerScores[a]!['distance'] as double;
          final distB = taskerScores[b]!['distance'] as double;
          return distA.compareTo(distB);
        });
        debugPrint("Limit is true, returning sorted taskers: ${result.length}");
      } else {
        result = matchedTaskers;
        debugPrint(
            "Limit is false, returning only matched taskers: ${result.length}");
      }

      debugPrint("Matched taskers: ${matchedTaskers.length}");
      debugPrint("Unmatched taskers: ${unmatchedTaskers.length}");
      for (var tasker in result) {
        debugPrint("Final Result Tasker: ${tasker.user?.firstName}, "
            "Specialization: ${tasker.specialization}, Score: ${taskerScores[tasker]!['score']}, "
            "Distance: ${taskerScores[tasker]!['distance']}");
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint("Error in getAllTaskers: $e");
      debugPrint(stackTrace.toString());
      return [];
    }
  }
}
