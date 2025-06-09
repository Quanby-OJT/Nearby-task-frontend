import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/setting_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/setting.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/set-up_address.dart';
import 'package:flutter_fe/view/setting/tasker_specialization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final GetStorage storage = GetStorage();
  final SettingController _settingController = SettingController();
  final JobPostService jobPostService = JobPostService();
  final ProfileController _profileController = ProfileController();
  List<MapEntry<int, String>> categories = [];
  Map<String, bool> selectedCategories = {};
  final int _selectedCategoriesCount = 0;
  bool _showFurtherAway = true;
  double _maxDistance = 19;
  RangeValues _ageRange = const RangeValues(18, 24);
  bool _isLoading = false;
  String? _userLocation;
  SettingModel _userPreference = SettingModel();
  String? _cityName;
  String? _province;
  Timer? _debounceTimer;
  AuthenticatedUser? tasker;
  String _role = "Loading...";

  @override
  void initState() {
    super.initState();

    fetchUserPreference();
  }

  Future<void> _fetchTaskerDetails() async {
    final userId = storage.read("user_id");

    try {
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(userId);

      setState(() {
        tasker = user;
        _role = user?.user.role ?? 'Unknown';
      });

      debugPrint("Fetched tasker details: $_role");
    } catch (e) {
      debugPrint("Error fetching tasker details: $e");
    }
  }

  Future<void> fetchUserPreference() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _settingController.getLocation().then((userPreference) {
          setState(() {
            _userPreference = userPreference ?? SettingModel();
            _showFurtherAway = _userPreference.limit ?? false;
            _maxDistance =
                (_userPreference.distance?.toDouble() ?? 19).clamp(1, 100);
            _ageRange = RangeValues(
              (_userPreference.ageRange?.start ?? 18).clamp(18, 80),
              (_userPreference.ageRange?.end ?? 24).clamp(18, 80),
            );
          });
        }),
        _fetchSpecialization(),
        _fetchTaskerDetails(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching user preference: $e');
      setState(() {
        _userPreference = SettingModel();
        _userLocation = "Set location";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        categories = [
          MapEntry(0, 'All'),
          ...fetchedSpecializations
              .map((spec) => MapEntry(spec.id!, spec.specialization))
        ];
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load categories. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setDistance() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _debouncedSetDistance();
    });
  }

  void _debouncedSetDistance() async {
    try {
      await _settingController.updateDistance(
          _maxDistance, _ageRange, _showFurtherAway);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save specialization. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOCATION',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_pin,
                                color: Color(0xFFB71A4A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_userPreference.city}, ${_userPreference.province}' ??
                                    "Set location",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SetUpAddressScreen(),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _showFurtherAway =
                                      _userPreference.limit ?? false;
                                });
                                await fetchUserPreference();
                              }
                            },
                            child: Text(
                              'Update your location',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Text(
                            'Change locations to find matches anywhere.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MAXIMUM DISTANCE',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${_maxDistance.round()}km.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _maxDistance,
                            min: 1,
                            max: 100,
                            onChanged: (value) {
                              setState(() {
                                _maxDistance = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _setDistance();
                            },
                            activeColor: const Color(0xFFB71A4A),
                            inactiveColor: Colors.grey[300],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Show people further away if I run out of profiles to see',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _showFurtherAway,
                                onChanged: (value) {
                                  setState(() {
                                    _showFurtherAway = value;
                                  });
                                  _setDistance();
                                },
                                activeColor: const Color(0xFFB71A4A),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
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
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'SPECIALIZATION WITH',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _userPreference.specialization != null &&
                                  _userPreference.specialization!.isNotEmpty
                              ? _userPreference.specialization!
                                  .map((idStr) {
                                    final category = categories.firstWhere(
                                      (c) => c.key.toString() == idStr,
                                      orElse: () => MapEntry(-1, 'Unknown'),
                                    );
                                    return category.key != -1
                                        ? category.value
                                        : null;
                                  })
                                  .where((name) => name != null)
                                  .join(', ')
                              : categories.isNotEmpty
                                  ? categories[0].value
                                  : 'All',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TaskerSpecializationScreen(),
                            ),
                          ).then((_) => fetchUserPreference());
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_role != "Tasker")
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AGE RANGE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _ageRange,
                              min: 18,
                              max: 80,
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _ageRange = values;
                                });
                              },
                              onChangeEnd: (RangeValues values) {
                                _setDistance();
                              },
                              activeColor: const Color(0xFFB71A4A),
                              inactiveColor: Colors.grey[300],
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
