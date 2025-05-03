import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskerSpecializationScreen extends StatefulWidget {
  const TaskerSpecializationScreen({super.key});

  @override
  State<TaskerSpecializationScreen> createState() =>
      _TaskerSpecializationScreenState();
}

class _TaskerSpecializationScreenState
    extends State<TaskerSpecializationScreen> {
  final GetStorage storage = GetStorage();
  final JobPostService jobPostService = JobPostService();
  bool _isCategoriesLoading = false;
  List<String> categories = [
    'All',
  ];
  Map<String, bool> selectedCategories = {};
  int _selectedCategoriesCount = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedCategories = {for (var category in categories) category: false};
      _selectedCategoriesCount = 0;
    });
    fetchSpecialization();
  }

  Future<void> fetchSpecialization() async {
    try {
      setState(() {
        _isCategoriesLoading = true;
      });

      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        categories = [
          'All',
          ...fetchedSpecializations.map((spec) => spec.specialization)
        ];
        selectedCategories = {for (var category in categories) category: false};
        _isCategoriesLoading = false;
        _selectedCategoriesCount = 0;
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
        _selectedCategoriesCount = 1;
      } else if (category != 'All') {
        selectedCategories['All'] = false;
        _selectedCategoriesCount = selectedCategories.entries
            .where((entry) => entry.key != 'All' && entry.value)
            .length;
      } else {
        _selectedCategoriesCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 197, 197),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Specialization',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
      body: SingleChildScrollView(
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
                    _isCategoriesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: categories.map((category) {
                              return GestureDetector(
                                onTap: () => toggleCategory(category),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: selectedCategories[category]!
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
                                        category,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (selectedCategories[category]!)
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
