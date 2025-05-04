import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../model/setting.dart';

class TaskerSpecializationScreen extends StatefulWidget {
  const TaskerSpecializationScreen({super.key});

  @override
  State<TaskerSpecializationScreen> createState() =>
      _TaskerSpecializationScreenState();
}

class _TaskerSpecializationScreenState
    extends State<TaskerSpecializationScreen> {
  final GetStorage storage = GetStorage();
  final SettingController settingController = SettingController();
  final JobPostService jobPostService = JobPostService();
  SettingModel _userPreference = SettingModel();
  bool _isCategoriesLoading = false;
  bool _isSaving = false;
  List<MapEntry<int, String>> categories = [MapEntry(0, 'All')];
  List<SpecializationModel> fetchedSpecializations = [];
  Map<String, bool> selectedCategories = {};
  int _selectedCategoriesCount = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSpecialization() async {
    try {
      setState(() {
        _isCategoriesLoading = true;
      });

      fetchedSpecializations = await jobPostService.getSpecializations();

      setState(() {
        categories = [
          MapEntry(0, 'All'),
          ...fetchedSpecializations
              .where((spec) => spec.id != null)
              .map((spec) => MapEntry(spec.id!, spec.specialization)),
        ];
        selectedCategories = {
          for (var category in categories) category.value: false
        };
        _isCategoriesLoading = false;
        _selectedCategoriesCount = 0;
      });

      await fetchUserPreference();
    } catch (error) {
      setState(() {
        _isCategoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load categories. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchUserPreference() async {
    try {
      final userPreference = await settingController.getLocation();

      setState(() {
        _userPreference = userPreference ?? SettingModel();
        selectedCategories
            .updateAll((key, value) => false); // Reset all to false
        if (_userPreference.specialization != null &&
            _userPreference.specialization!.isNotEmpty) {
          for (var idStr in _userPreference.specialization!) {
            final category = categories.firstWhere(
              (c) => c.key.toString() == idStr,
              orElse: () => MapEntry(-1, ''),
            );
            if (category.key != -1) {
              selectedCategories[category.value] = true;
            }
          }
          _selectedCategoriesCount = selectedCategories.entries
              .where((entry) => entry.value && entry.key != 'All')
              .length;
          if (selectedCategories['All']!) {
            _selectedCategoriesCount = 1;
            // Ensure only 'All' is highlighted if '0' is in specialization
            selectedCategories
                .updateAll((key, value) => key == 'All' ? true : false);
          }
        }
      });

      debugPrint('User preference: ${_userPreference.specialization}');
      debugPrint('Selected categories: $selectedCategories');
    } catch (e) {
      debugPrint('Error fetching user preference: $e');
      setState(() {
        _userPreference = SettingModel();
      });
    }
  }

  void toggleCategory(String category) {
    setState(() {
      selectedCategories[category] = !selectedCategories[category]!;
      if (category == 'All' && selectedCategories['All']!) {
        selectedCategories
            .updateAll((key, value) => key == 'All' ? true : false);
        _selectedCategoriesCount = 1;
      } else {
        selectedCategories['All'] = false;
        _selectedCategoriesCount = selectedCategories.entries
            .where((entry) => entry.value && entry.key != 'All')
            .length;
      }
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_selectedCategoriesCount > 0 || selectedCategories['All']!) {
        _debouncedSaveSpecialization();
      }
    });
  }

  void _debouncedSaveSpecialization() async {
    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final selectedIds = selectedCategories['All']!
          ? ['0']
          : selectedCategories.entries
              .where((entry) => entry.value)
              .map((entry) {
                final category = categories.firstWhere(
                  (c) => c.value == entry.key,
                  orElse: () => MapEntry(-1, ''),
                );
                return category.key != -1 ? category.key.toString() : null;
              })
              .where((id) => id != null)
              .cast<String>()
              .toList();

      await settingController.updateSpecialization(selectedIds);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save specialization. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 197, 197),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Specialization',
              style: GoogleFonts.poppins(
                color: const Color(0xFFB71A4A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFB71A4A),
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isCategoriesLoading
          ? const Center(child: CustomLoading())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select all that apply to help us recommend the right task for you.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: categories.map((category) {
                              return GestureDetector(
                                onTap: _isSaving
                                    ? null
                                    : () => toggleCategory(category.value),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: selectedCategories[category.value]!
                                          ? const Color(0xFFB71A4A)
                                          : Colors.grey[300]!,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category.value,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (selectedCategories[category.value]!)
                                        const Icon(
                                          Icons.check,
                                          color: Color(0xFFB71A4A),
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "It's our mission to ensure that this is a safe and inclusive space for everyone. Learn why we ask for this info.",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Learn why we ask for this info.',
                              style: GoogleFonts.poppins(
                                color: Colors.blue,
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
