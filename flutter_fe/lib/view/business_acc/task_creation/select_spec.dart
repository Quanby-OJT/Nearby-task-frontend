import 'package:flutter/material.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectSpec extends StatefulWidget {
  const SelectSpec({super.key});

  @override
  State<SelectSpec> createState() => _SelectSpecState();
}

class _SelectSpecState extends State<SelectSpec> {
  final GetStorage storage = GetStorage();
  final JobPostService jobPostService = JobPostService();
  bool _isCategoriesLoading = false;
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

  void selectCategory(String category) {
    Navigator.pop(context, category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                            'Select a specialization to apply.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: categories.map((category) {
                              return GestureDetector(
                                onTap: () => selectCategory(category.value),
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