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
      // Fetch taskers, client data, and specializations
      final fetchedTaskers =
          await clientServices.fetchAllFilteredTasker(userId);
      final fetchedMyData = await clientServices.fetchMyData(userId);
      final fetchedSpecializations = await jobPostService.getSpecializations();

      // Create specialization map for ID-to-name lookup
      final specializationMap = {
        0: 'All',
        for (var spec
            in fetchedSpecializations.where((spec) => spec.id != null))
          spec.id!: spec.specialization,
      };

      debugPrint("My data: $fetchedMyData");
      debugPrint("Fetched Taskers: ${fetchedTaskers.length} taskers");
      debugPrint("Specialization Map: $specializationMap");

      // Check if client preferences exist
      if (fetchedMyData?.user == null ||
          fetchedMyData?.user?.userPreferences == null ||
          fetchedMyData?.user?.userPreferences?.isEmpty == true) {
        debugPrint("No client preferences found, returning all taskers");
        return fetchedTaskers;
      }

      final clientPreferences = fetchedMyData!.user!.userPreferences!.first;

      // Parse specialization preferences
      final desiredSpecializationIds = <int>[];
      final desiredSpecializationNames = <String>[];

      if (clientPreferences.specialization.isNotEmpty) {
        for (final item in clientPreferences.specialization) {
          try {
            if (item.startsWith('[') && item.endsWith(']')) {
              final List<dynamic> ids = jsonDecode(item);
              for (final idStr in ids) {
                final id = int.tryParse(idStr.toString().trim());
                if (id != null && specializationMap.containsKey(id)) {
                  desiredSpecializationIds.add(id);
                  if (id != 0) {
                    desiredSpecializationNames.add(specializationMap[id]!);
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
      }

      final includesAllSpecializations = desiredSpecializationIds.contains(0);

      debugPrint("Desired specialization IDs: $desiredSpecializationIds");
      debugPrint("Desired specialization names: $desiredSpecializationNames");
      debugPrint("Includes all specializations: $includesAllSpecializations");

      // Extract client preferences
      final clientLat = clientPreferences.address.latitude ?? 0.0;
      final clientLon = clientPreferences.address.longitude ?? 0.0;
      final maxDistance = clientPreferences.distance;
      final ageStart = clientPreferences.ageStart;
      final ageEnd = clientPreferences.ageEnd;
      final limit = clientPreferences.limit;

      debugPrint(
          "Client Preferences - Limit: $limit, Max Distance: $maxDistance, "
          "Age Range: $ageStart-$ageEnd");

      // Utility functions
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

      int calculateAge(DateTime birthdate) {
        final now = DateTime.now();
        int age = now.year - birthdate.year;
        if (now.month < birthdate.month ||
            (now.month == birthdate.month && now.day < birthdate.day)) {
          age--;
        }
        return age;
      }

      // Process taskers
      List<TaskerModel> matchedTaskers = [];
      List<TaskerModel> unmatchedTaskers = [];
      final taskerScores = <TaskerModel, Map<String, dynamic>>{};

      for (var tasker in fetchedTaskers) {
        // Initialize scoring
        int score = 0;
        double distance = double.infinity;
        double rating =
            tasker.rating ?? 0.0; // Use tasker.rating, default to 0.0

        // Check specialization match (highest priority)
        bool matchesSpecialization = includesAllSpecializations ||
            desiredSpecializationNames.isEmpty ||
            desiredSpecializationNames
                .contains(tasker.taskerSpecialization?.specialization);
        if (matchesSpecialization) {
          score += 10; // High weight for specialization
        }

        // Check distance
        final taskerLat = tasker.user?.userPreferences?.isNotEmpty == true
            ? tasker.user!.userPreferences!.first.address.latitude ?? 0.0
            : 0.0;
        final taskerLon = tasker.user?.userPreferences?.isNotEmpty == true
            ? tasker.user!.userPreferences!.first.address.longitude ?? 0.0
            : 0.0;

        bool matchesDistance = true;
        if (clientLat != 0.0 &&
            clientLon != 0.0 &&
            taskerLat != 0.0 &&
            taskerLon != 0.0) {
          distance =
              calculateDistance(clientLat, clientLon, taskerLat, taskerLon);
          if (distance <= maxDistance) {
            score += 5; // Medium weight for distance
          } else {
            matchesDistance = false;
          }
        } else {
          score += 5; // Default match if coordinates are missing
        }

        // Check age
        bool matchesAge = true;
        if (tasker.user?.birthdate != null) {
          try {
            final birthdate = DateTime.parse(tasker.user!.birthdate!);
            final age = calculateAge(birthdate);
            if (age >= ageStart && age <= ageEnd) {
              score += 3; // Lower weight for age
            } else {
              matchesAge = false;
            }
          } catch (e) {
            debugPrint("Error parsing birthdate: ${tasker.user!.birthdate}");
            score += 3; // Default match if birthdate is invalid
          }
        } else {
          score += 3; // Default match if birthdate is missing
        }

        debugPrint(
            "Tasker: ${tasker.user?.firstName}, Specialization: ${tasker.taskerSpecialization?.specialization}, "
            "Matches Specialization: $matchesSpecialization, Matches Distance: $matchesDistance, "
            "Matches Age: $matchesAge, Distance: $distance, Score: $score, Rating: $rating");

        // Categorize taskers
        if (matchesSpecialization && matchesDistance && matchesAge) {
          matchedTaskers.add(tasker);
        } else {
          unmatchedTaskers.add(tasker);
        }

        taskerScores[tasker] = {
          'score': score,
          'distance': distance,
          'rating': rating,
        };
      }

      // Sort matched taskers by score (descending), then rating (descending), then distance (ascending)
      matchedTaskers.sort((a, b) {
        final scoreA = taskerScores[a]!['score'] as int;
        final scoreB = taskerScores[b]!['score'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        final ratingA = taskerScores[a]!['rating'] as double;
        final ratingB = taskerScores[b]!['rating'] as double;
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA); // Higher rating first
        }
        final distA = taskerScores[a]!['distance'] as double;
        final distB = taskerScores[b]!['distance'] as double;
        return distA.compareTo(distB); // Closer distance first
      });

      // Sort unmatched taskers by score (descending), then rating (descending), then distance (ascending)
      unmatchedTaskers.sort((a, b) {
        final scoreA = taskerScores[a]!['score'] as int;
        final scoreB = taskerScores[b]!['score'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        final ratingA = taskerScores[a]!['rating'] as double;
        final ratingB = taskerScores[b]!['rating'] as double;
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA); // Higher rating first
        }
        final distA = taskerScores[a]!['distance'] as double;
        final distB = taskerScores[b]!['distance'] as double;
        return distA.compareTo(distB); // Closer distance first
      });

      // Combine results based on limit preference
      List<TaskerModel> result =
          limit ? [...matchedTaskers, ...unmatchedTaskers] : matchedTaskers;

      // Final sort to ensure highest score and rating appear first
      result.sort((a, b) {
        final scoreA = taskerScores[a]!['score'] as int;
        final scoreB = taskerScores[b]!['score'] as int;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher score first
        }
        final ratingA = taskerScores[a]!['rating'] as double;
        final ratingB = taskerScores[b]!['rating'] as double;
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA); // Higher rating first
        }
        final distA = taskerScores[a]!['distance'] as double;
        final distB = taskerScores[b]!['distance'] as double;
        return distA.compareTo(distB); // Closer distance first
      });

      debugPrint("Matched taskers: ${matchedTaskers.length}");
      debugPrint("Unmatched taskers: ${unmatchedTaskers.length}");
      debugPrint("Total taskers returned: ${result.length}");
      for (var tasker in result) {
        debugPrint("Final Result Tasker: ${tasker.user?.firstName}, "
            "Specialization: ${tasker.taskerSpecialization?.specialization}, "
            "Score: ${taskerScores[tasker]!['score']}, "
            "Rating: ${taskerScores[tasker]!['rating']}, "
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
