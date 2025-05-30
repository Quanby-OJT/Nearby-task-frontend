import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectRelatedSpec extends StatefulWidget {
  const SelectRelatedSpec({super.key});

  @override
  State<SelectRelatedSpec> createState() => _SelectRelatedSpecState();
}

class _SelectRelatedSpecState extends State<SelectRelatedSpec> {
  final GetStorage storage = GetStorage();
  final SettingController settingController = SettingController();
  final JobPostService jobPostService = JobPostService();
  final SettingModel _userPreference = SettingModel();
  bool _isCategoriesLoading = false;
  bool _isSaving = false;
  List<MapEntry<int, String>> categories = [];
  List<SpecializationModel> fetchedSpecializations = [];
  Map<String, bool> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
  }

  Future<void> fetchSpecialization() async {
  try {
    setState(() {
      _isCategoriesLoading = true;
    });

    fetchedSpecializations = await jobPostService.getSpecializations();

    setState(() {
      categories = fetchedSpecializations
          .where((spec) => spec.id != null)
          .map((spec) => MapEntry(spec.id!, spec.specialization))
          .toList();
      selectedCategories = {
        for (var category in categories) category.value: false
      };
      _isCategoriesLoading = false;
    });
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

  void toggleCategory(String category) {
    setState(() {
      selectedCategories[category] = !selectedCategories[category]!;
      if (category == 'All' && selectedCategories['All']!) {
        selectedCategories
            .updateAll((key, value) => key == 'All' ? true : false);
      } else if (category != 'All') {
        selectedCategories['All'] = false;
      }
    });
  }

  void saveSelections() {
    setState(() {
      _isSaving = true;
    });
   
    List<String> selected = selectedCategories['All']! &&
            selectedCategories.entries
                    .where((entry) => entry.value && entry.key != 'All')
                    .isEmpty
        ? ['All']
        : selectedCategories.entries
            .where((entry) => entry.value && entry.key != 'All')
            .map((entry) => entry.key)
            .toList();
    Navigator.pop(context, selected);
    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
        backgroundColor: Colors.grey[100],
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : saveSelections,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: _isSaving ? Colors.grey : const Color(0xFFB71A4A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                            "It's our mission to ensure that this is a safe and inclusive space for everyone.",
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