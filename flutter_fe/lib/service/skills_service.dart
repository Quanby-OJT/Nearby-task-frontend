import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';

class SkillsService {
  // Singleton instance
  static final SkillsService _instance = SkillsService._internal();

  // Cache data to reduce API calls
  final Map<String, dynamic> _cache = {};

  // Job post service to fetch specializations
  final JobPostService _jobPostService = JobPostService();

  // Storage for auth token
  final GetStorage storage = GetStorage();

  // Factory constructor
  factory SkillsService() {
    return _instance;
  }

  // Private constructor
  SkillsService._internal();

  // Direct API test to check if the specializations endpoint is working
  Future<void> testSpecializationsAPI() async {
    try {
      debugPrint(
          'SkillsService: Testing direct API call to specializations endpoint...');

      final String token = await AuthService.getSessionToken();

      final String apiUrl = JobPostService.url;
      debugPrint('SkillsService: Using API URL: $apiUrl');

      final response = await http.get(
        Uri.parse('$apiUrl/get-specializations'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      debugPrint(
          'SkillsService: Direct API response status: ${response.statusCode}');
      debugPrint('SkillsService: Direct API response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data.containsKey('specializations')) {
          final List<dynamic> specializations = data['specializations'];
          debugPrint(
              'SkillsService: Direct API call found ${specializations.length} specializations');
        } else {
          debugPrint(
              'SkillsService: Direct API call response does not contain specializations key');
        }
      } else {
        debugPrint(
            'SkillsService: Direct API call failed with status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('SkillsService: Error in direct API test: $e');
      debugPrint('SkillsService: Stack trace: $stackTrace');
    }
  }

  // Direct method to fetch specializations from API
  Future<List<SpecializationModel>> getSpecializationsDirectly() async {
    try {
      debugPrint(
          'SkillsService: Fetching specializations directly from API...');

      final String token = await AuthService.getSessionToken();

      final String apiUrl = JobPostService.url;

      final response = await http.get(
        Uri.parse('$apiUrl/get-specializations'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data.containsKey('specializations')) {
          final List<dynamic> specializationList =
              data['specializations'] as List;
          debugPrint(
              'SkillsService: Direct fetch found ${specializationList.length} specializations');

          // Create a set to track seen specializations to avoid duplicates
          final Set<String> seenSpecializations = {};

          // Generate a unique ID for each specialization if needed
          return specializationList.asMap().entries.map((entry) {
            final int index = entry.key;
            final dynamic item = entry.value;

            // Create a map if the item isn't already one
            final Map<String, dynamic> specMap = item is Map<String, dynamic>
                ? item
                : {'specialization': item.toString()};

            // Ensure each specialization has a unique ID
            if (!specMap.containsKey('spec_id') || specMap['spec_id'] == null) {
              specMap['spec_id'] = index + 1; // Use index + 1 as fallback ID
            }

            // Ensure specialization name is unique
            String specialization =
                specMap['specialization']?.toString() ?? 'Unknown';
            if (seenSpecializations.contains(specialization)) {
              int counter = 1;
              String newName;
              do {
                newName = '$specialization ($counter)';
                counter++;
              } while (seenSpecializations.contains(newName));
              specialization = newName;
              specMap['specialization'] = specialization;
            }
            seenSpecializations.add(specialization);

            return SpecializationModel.fromJson(specMap);
          }).toList();
        } else {
          debugPrint(
              'SkillsService: Direct fetch response does not contain specializations key');
        }
      } else {
        debugPrint(
            'SkillsService: Direct fetch failed with status ${response.statusCode}');
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('SkillsService: Error in direct specialization fetch: $e');
      debugPrint('SkillsService: Stack trace: $stackTrace');
      return [];
    }
  }

  // Get all skills (specializations from database)
  Future<List<Map<String, dynamic>>> getSkills() async {
    try {
      // First, run the API test to check connectivity
      await testSpecializationsAPI();

      // Check cache first
      if (_cache.containsKey('skills')) {
        debugPrint('SkillsService: Returning cached skills data');
        return List<Map<String, dynamic>>.from(_cache['skills']);
      }

      debugPrint('SkillsService: Fetching specializations from database...');

      // Try to fetch specializations using JobPostService
      List<SpecializationModel> specializations =
          await _jobPostService.getSpecializations();

      // Debug the response from JobPostService
      debugPrint(
          'SkillsService: JobPostService returned ${specializations.length} specializations');
      if (specializations.isNotEmpty) {
        debugPrint(
            'SkillsService: First specialization from JobPostService: ${specializations.first.id} - ${specializations.first.specialization}');
      } else {
        debugPrint('SkillsService: JobPostService returned empty list');
      }

      // If that fails, try direct API call as fallback
      if (specializations.isEmpty) {
        debugPrint(
            'SkillsService: JobPostService returned empty list, trying direct API call...');
        specializations = await getSpecializationsDirectly();

        // Debug the response from direct API call
        debugPrint(
            'SkillsService: Direct API call returned ${specializations.length} specializations');
        if (specializations.isNotEmpty) {
          debugPrint(
              'SkillsService: First specialization from direct API: ${specializations.first.id} - ${specializations.first.specialization}');
        } else {
          debugPrint('SkillsService: Direct API call returned empty list');
        }
      }

      debugPrint(
          'SkillsService: Fetched ${specializations.length} specializations from database');

      // If still no specializations, use fallback data
      if (specializations.isEmpty) {
        debugPrint(
            'SkillsService: No specializations found in database, using fallback data');
        return _getFallbackSkills();
      }

      // Log the first few specializations for debugging
      if (specializations.isNotEmpty) {
        debugPrint(
            'SkillsService: First specialization: ${specializations.first.id} - ${specializations.first.specialization}');
      }

      // Convert to required format
      final List<Map<String, dynamic>> skills =
          specializations.asMap().entries.map((entry) {
        final index = entry.key;
        final spec = entry.value;
        return {
          'id':
              spec.id?.toString() ?? (index + 1).toString(), // Ensure unique ID
          'name': spec.specialization,
          'category': 'Specialization',
        };
      }).toList();

      // Debug the converted skills
      debugPrint(
          'SkillsService: Converted ${skills.length} specializations to skills format');
      if (skills.isNotEmpty) {
        debugPrint('SkillsService: First converted skill: ${skills.first}');
      }

      // Sort skills by name
      skills.sort((a, b) => a['name'].compareTo(b['name']));

      // Make sure all required fields are present and unique
      final Set<String> usedIds = {};
      final Set<String> usedNames = {};

      for (int i = 0; i < skills.length; i++) {
        var skill = skills[i];

        // Ensure ID is present and unique
        if (skill['id'] == null ||
            skill['id'].toString().isEmpty ||
            usedIds.contains(skill['id'])) {
          // Generate a new unique ID
          String newId = (i + 1000).toString();
          while (usedIds.contains(newId)) {
            newId = (int.parse(newId) + 1).toString();
          }
          debugPrint(
              'SkillsService: Fixing duplicate/missing ID for skill: ${skill['name']} -> $newId');
          skill['id'] = newId;
        }
        usedIds.add(skill['id'].toString());

        // Ensure name is present and unique
        if (skill['name'] == null || skill['name'].toString().isEmpty) {
          skill['name'] = 'Unknown Specialization ${i + 1}';
        }

        String name = skill['name'].toString();
        if (usedNames.contains(name)) {
          int counter = 1;
          String newName;
          do {
            newName = '$name ($counter)';
            counter++;
          } while (usedNames.contains(newName));

          debugPrint('SkillsService: Fixing duplicate name: $name -> $newName');
          skill['name'] = newName;
        }
        usedNames.add(skill['name'].toString());
      }

      // Cache the result
      _cache['skills'] = skills;

      debugPrint(
          'SkillsService: Successfully processed and cached ${skills.length} skills');

      return skills;
    } catch (e, stackTrace) {
      debugPrint('SkillsService: Error fetching skills from database: $e');
      debugPrint('SkillsService: Stack trace: $stackTrace');
      // Return fallback data if database fetch fails
      return _getFallbackSkills();
    }
  }

  // Search skills by query
  Future<List<Map<String, dynamic>>> searchSkills(String query) async {
    try {
      final List<Map<String, dynamic>> allSkills = await getSkills();

      if (query.isEmpty) {
        return allSkills;
      }

      final String lowercaseQuery = query.toLowerCase();

      return allSkills
          .where((skill) =>
              skill['name'].toString().toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      debugPrint('Error searching skills: $e');
      return [];
    }
  }

  // Get skills by category
  Future<List<Map<String, dynamic>>> getSkillsByCategory(
      String category) async {
    try {
      final List<Map<String, dynamic>> allSkills = await getSkills();

      return allSkills.where((skill) => skill['category'] == category).toList();
    } catch (e) {
      debugPrint('Error fetching skills by category: $e');
      return [];
    }
  }

  // Fallback data - used if database fetch fails
  List<Map<String, dynamic>> _getFallbackSkills() {
    return [
      {'id': '1', 'name': 'Web Development', 'category': 'Technology'},
      {'id': '2', 'name': 'Mobile App Development', 'category': 'Technology'},
      {'id': '3', 'name': 'UI/UX Design', 'category': 'Design'},
      {'id': '4', 'name': 'Graphic Design', 'category': 'Design'},
      {'id': '5', 'name': 'Content Writing', 'category': 'Writing'},
      {'id': '6', 'name': 'Digital Marketing', 'category': 'Marketing'},
      {'id': '7', 'name': 'SEO', 'category': 'Marketing'},
      {'id': '8', 'name': 'Data Analysis', 'category': 'Data'},
      {'id': '9', 'name': 'Machine Learning', 'category': 'Data'},
      {'id': '10', 'name': 'Project Management', 'category': 'Management'},
      {'id': '11', 'name': 'Customer Service', 'category': 'Support'},
      {'id': '12', 'name': 'Accounting', 'category': 'Finance'},
      {'id': '13', 'name': 'Translation', 'category': 'Language'},
      {'id': '14', 'name': 'Video Editing', 'category': 'Multimedia'},
      {'id': '15', 'name': 'Photography', 'category': 'Multimedia'},
      {'id': '16', 'name': 'Voice Acting', 'category': 'Multimedia'},
      {'id': '17', 'name': 'Administrative Support', 'category': 'Support'},
      {'id': '18', 'name': 'Legal Services', 'category': 'Legal'},
      {'id': '19', 'name': 'Teaching', 'category': 'Education'},
      {'id': '20', 'name': 'Tutoring', 'category': 'Education'},
      {'id': '21', 'name': 'Carpentry', 'category': 'Trades'},
      {'id': '22', 'name': 'Plumbing', 'category': 'Trades'},
      {'id': '23', 'name': 'Electrical Work', 'category': 'Trades'},
      {'id': '24', 'name': 'Painting', 'category': 'Trades'},
      {'id': '25', 'name': 'Gardening', 'category': 'Home Services'},
      {'id': '26', 'name': 'Cleaning', 'category': 'Home Services'},
      {'id': '27', 'name': 'Cooking', 'category': 'Food Services'},
      {'id': '28', 'name': 'Baking', 'category': 'Food Services'},
      {'id': '29', 'name': 'Driving', 'category': 'Transportation'},
      {'id': '30', 'name': 'Delivery', 'category': 'Transportation'},
    ];
  }
}
