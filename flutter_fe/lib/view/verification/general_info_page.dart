import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/philippines_location_service.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/service/skills_service.dart';
import 'package:flutter_fe/widgets/searchable_dropdown.dart';
import 'dart:convert';

class GeneralInfoPage extends StatefulWidget {
  final Function(Map<String, dynamic> userInfo) onInfoCompleted;

  const GeneralInfoPage({super.key, required this.onInfoCompleted});

  @override
  State<GeneralInfoPage> createState() => _GeneralInfoPageState();
}

class _GeneralInfoPageState extends State<GeneralInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final GetStorage storage = GetStorage();
  final PhilippineLocationService _locationService =
      PhilippineLocationService();
  final ProfileController _profileController = ProfileController();
  final SkillsService _skillsService = SkillsService();

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();

  // Form data
  String? _gender;
  DateTime? _birthdate;
  bool _isLoading = false;
  bool _isLoadingSkills = false;
  String _payPeriod = 'Hourly'; // Default pay period

  // Pay period options
  final List<String> _payPeriodOptions = [
    'Hourly',
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly'
  ];

  // Address data
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedCity;
  Map<String, dynamic>? _selectedBarangay;

  // Skills data
  List<Map<String, dynamic>> _allSkills = [];
  List<Map<String, dynamic>> _selectedSkills = [];
  String _skillsSearchQuery = '';
  int? _selectedSpecializationId;

  // Location data lists
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _barangays = [];

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _isLoadingSkills = true;

    Future.microtask(() {
      _loadUserData();
      _loadRegions();
      _loadSkills();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _postalCodeController.dispose();
    _birthdateController.dispose();
    _skillsController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoading = true);
    try {
      final regions = await _locationService.getRegions();
      setState(() {
        _regions = regions;
      });
    } catch (e) {
      debugPrint('Error loading regions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProvinces(String regionCode) async {
    setState(() => _isLoading = true);
    try {
      final provinces = await _locationService.getProvincesByRegion(regionCode);
      setState(() {
        _provinces = provinces;
        _cities = [];
        _barangays = [];
      });
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() => _isLoading = true);
    try {
      final cities = await _locationService.getCitiesByProvince(provinceCode);
      setState(() {
        _cities = cities;
        _barangays = [];
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBarangays(String cityCode) async {
    setState(() => _isLoading = true);
    try {
      final barangays = await _locationService.getBarangaysByCity(cityCode);
      setState(() {
        _barangays = barangays;
      });
    } catch (e) {
      debugPrint('Error loading barangays: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSkills() async {
    try {
      debugPrint('GeneralInfoPage: Starting to load skills/specializations...');
      setState(() => _isLoadingSkills = true);

      // First check if we have a valid auth token
      final token = storage.read('session');
      debugPrint('GeneralInfoPage: Auth token available: ${token != null}');

      // Get skills from service
      final skills = await _skillsService.getSkills();

      // Make sure we're still mounted before updating state
      if (!mounted) {
        debugPrint(
            'GeneralInfoPage: Widget no longer mounted, aborting state update');
        return;
      }

      debugPrint(
          'GeneralInfoPage: Loaded ${skills.length} skills/specializations');

      if (skills.isEmpty) {
        debugPrint(
            'GeneralInfoPage: Warning - No skills/specializations were loaded');
        setState(() {
          _allSkills = [];
          _isLoadingSkills = false;
          _selectedSkills = [];
          _selectedSpecializationId = null;
        });
        return;
      }

      // Log a few skills for debugging
      debugPrint('GeneralInfoPage: First few skills:');
      for (int i = 0; i < (skills.length > 3 ? 3 : skills.length); i++) {
        debugPrint('  - ${skills[i]['id']}: ${skills[i]['name']}');
      }

      // Debug the current state before updating
      debugPrint(
          'GeneralInfoPage: Current _allSkills length: ${_allSkills.length}');
      debugPrint(
          'GeneralInfoPage: Current _selectedSkills length: ${_selectedSkills.length}');
      debugPrint(
          'GeneralInfoPage: Current _skillsController text: ${_skillsController.text}');

      // Store the current selection before updating
      final String currentSelection = _skillsController.text;

      // Update the state with the loaded skills
      setState(() {
        _allSkills = List<Map<String, dynamic>>.from(
            skills); // Create a new list to ensure state update
        _isLoadingSkills = false;

        // Clear the current selection
        _selectedSkills = [];
        _selectedSpecializationId = null;

        // If we have a stored specialization from user data, select it
        if (currentSelection.isNotEmpty) {
          debugPrint(
              'GeneralInfoPage: Looking for stored specialization: $currentSelection');

          // Try to find an exact match first
          final exactMatches = _allSkills.where((skill) =>
              skill['name'].toString().toLowerCase() ==
              currentSelection.toLowerCase());

          if (exactMatches.isNotEmpty) {
            _selectedSkills = [exactMatches.first];
            _selectedSpecializationId =
                int.tryParse(exactMatches.first['id'].toString());
            _skillsController.text = exactMatches.first['name'].toString();
            debugPrint(
                'GeneralInfoPage: Found exact match with ID: ${_selectedSpecializationId}');
          } else {
            // Try to find a partial match
            final partialMatches = _allSkills.where((skill) => skill['name']
                .toString()
                .toLowerCase()
                .contains(currentSelection.toLowerCase()));

            if (partialMatches.isNotEmpty) {
              _selectedSkills = [partialMatches.first];
              _selectedSpecializationId =
                  int.tryParse(partialMatches.first['id'].toString());
              _skillsController.text = partialMatches.first['name'].toString();
              debugPrint(
                  'GeneralInfoPage: Found partial match with ID: ${_selectedSpecializationId}');
            } else {
              debugPrint(
                  'GeneralInfoPage: No matching specialization found for: $currentSelection');
              _skillsController.text = '';
            }
          }
        }
      });

      // Debug the state after updating
      debugPrint(
          'GeneralInfoPage: After setState - _allSkills length: ${_allSkills.length}');
      debugPrint(
          'GeneralInfoPage: After setState - _selectedSkills length: ${_selectedSkills.length}');
      debugPrint(
          'GeneralInfoPage: After setState - _isLoadingSkills: $_isLoadingSkills');
      debugPrint(
          'GeneralInfoPage: After setState - _selectedSpecializationId: $_selectedSpecializationId');
    } catch (e, stackTrace) {
      debugPrint('GeneralInfoPage: Error loading skills: $e');
      debugPrint('GeneralInfoPage: Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoadingSkills = false;
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load specializations. Using default values.'),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    }
  }

  Future<void> _searchSkills(String query) async {
    _skillsSearchQuery = query;
    debugPrint('GeneralInfoPage: Searching skills with query: "$query"');

    try {
      setState(() => _isLoadingSkills = true);

      final skills = await _skillsService.searchSkills(query);

      debugPrint('GeneralInfoPage: Search returned ${skills.length} skills');

      if (mounted) {
        setState(() {
          _allSkills = skills;
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      debugPrint('GeneralInfoPage: Error searching skills: $e');
      if (mounted) {
        setState(() {
          _isLoadingSkills = false;
        });
      }
    }
  }

  void _onSkillsSelected(List<Map<String, dynamic>> skills) {
    setState(() {
      _selectedSkills = skills;
      _skillsController.text =
          skills.map((skill) => skill['name'] as String).join(', ');
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Get user ID from storage
      final userId = storage.read('user_id');
      if (userId != null) {
        // Fetch authenticated user data from API
        final AuthenticatedUser? authUser = await _profileController
            .getAuthenticatedUser(context, int.parse(userId.toString()));

        if (authUser != null && mounted) {
          // Populate form fields with user data
          setState(() {
            _firstNameController.text = authUser.user.firstName;
            _lastNameController.text = authUser.user.lastName;

            if (authUser.user.middleName != null &&
                authUser.user.middleName!.isNotEmpty) {
              _middleNameController.text = authUser.user.middleName!;
            }

            _emailController.text = authUser.user.email;

            if (authUser.user.contact != null &&
                authUser.user.contact!.isNotEmpty) {
              _phoneController.text = authUser.user.contact!;
            }

            // Set gender if available
            if (authUser.user.gender != null &&
                authUser.user.gender!.isNotEmpty) {
              _gender = authUser.user.gender;
            }

            // Set birthdate if available
            if (authUser.user.birthdate != null &&
                authUser.user.birthdate!.isNotEmpty) {
              try {
                final DateTime parsedDate =
                    DateTime.parse(authUser.user.birthdate!);
                _birthdate = parsedDate;
                _birthdateController.text =
                    DateFormat('MM/dd/yyyy').format(parsedDate);
              } catch (e) {
                debugPrint('Error parsing birthdate: $e');
              }
            }

            // Load specialization if available (from tasker model)
            if (authUser.tasker != null &&
                authUser.tasker!.specialization != null) {
              _skillsController.text = authUser.tasker!.specialization!;
              // The _selectedSkills will be populated after loading all skills in _loadSkills()
            }
          });
        }
      }

      // Load region data that might be stored
      final dynamic regionData = storage.read('region');
      if (regionData != null && mounted) {
        // Handle case where regionData might be a string instead of a map
        if (regionData is String) {
          // Find the region from the loaded regions list once they're available
          _loadRegions().then((_) {
            if (_regions.isNotEmpty && mounted) {
              final matchingRegion = _regions.firstWhere(
                (region) =>
                    region['code'] == regionData ||
                    region['name'] == regionData,
                orElse: () => <String, dynamic>{},
              );

              if (matchingRegion.isNotEmpty && mounted) {
                setState(() {
                  _selectedRegion = matchingRegion;
                  if (matchingRegion['code'] != null) {
                    _loadProvinces(matchingRegion['code']);
                  }
                });
              }
            }
          });
        } else if (regionData is Map<String, dynamic>) {
          // It's already a map, use it directly
          setState(() {
            _selectedRegion = regionData;
            if (regionData['code'] != null) {
              _loadProvinces(regionData['code']);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      // Update loading state only if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthdate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 13)), // Minimum age 13 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0272B1),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _submitInfo() {
    if (_formKey.currentState!.validate()) {
      // Create a structured address object for JSON storage
      Map<String, dynamic> addressData = {
        'street': _streetAddressController.text,
        'barangay': _selectedBarangay is Map<String, dynamic>
            ? _selectedBarangay!['name']
            : null,
        'barangayCode': _selectedBarangay is Map<String, dynamic>
            ? _selectedBarangay!['code']
            : null,
        'city': _selectedCity is Map<String, dynamic>
            ? _selectedCity!['name']
            : null,
        'cityCode': _selectedCity is Map<String, dynamic>
            ? _selectedCity!['code']
            : null,
        'province': _selectedProvince is Map<String, dynamic>
            ? _selectedProvince!['name']
            : null,
        'provinceCode': _selectedProvince is Map<String, dynamic>
            ? _selectedProvince!['code']
            : null,
        'region': _selectedRegion is Map<String, dynamic>
            ? _selectedRegion!['name']
            : null,
        'regionCode': _selectedRegion is Map<String, dynamic>
            ? _selectedRegion!['code']
            : null,
        'postalCode': _postalCodeController.text,
        'country': 'Philippines'
      };

      // Convert to JSON string for storage
      String addressJson = jsonEncode(addressData);

      // Get specialization data
      String specialization =
          _selectedSkills.isNotEmpty ? _selectedSkills.first['name'] : '';
      int? specializationId = _selectedSpecializationId;

      // Parse wage value
      double? wage = double.tryParse(_wageController.text);

      // Create userInfo map with all the collected data
      Map<String, dynamic> userInfo = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'middleName': _middleNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'addressJson':
            addressJson, // Store the complete address as a JSON string
        'address': addressData, // Keep the structured data for immediate use
        'fullAddress': _buildFullAddress(),
        'gender': _gender,
        'birthdate': _birthdate != null
            ? DateFormat('yyyy-MM-dd').format(_birthdate!)
            : null,
        'specialization': specialization,
        'specializationId': specializationId,
        'payPeriod': _payPeriod,
        'wage': wage,
      };

      // Call the callback function with the map
      widget.onInfoCompleted(userInfo);
    }
  }

  // Build a formatted full address string
  String _buildFullAddress() {
    List<String> addressParts = [];

    if (_streetAddressController.text.isNotEmpty) {
      addressParts.add(_streetAddressController.text);
    }

    if (_selectedBarangay != null &&
        _selectedBarangay is Map<String, dynamic>) {
      addressParts.add('Barangay ${_selectedBarangay!['name']}');
    }

    if (_selectedCity != null && _selectedCity is Map<String, dynamic>) {
      addressParts.add(_selectedCity!['name']);
    }

    if (_selectedProvince != null &&
        _selectedProvince is Map<String, dynamic>) {
      addressParts.add(_selectedProvince!['name']);
    }

    if (_selectedRegion != null && _selectedRegion is Map<String, dynamic>) {
      addressParts.add(_selectedRegion!['name']);
    }

    if (_postalCodeController.text.isNotEmpty) {
      addressParts.add(_postalCodeController.text);
    }

    addressParts.add('Philippines');

    return addressParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0272B1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please provide your basic information for verification',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Note box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please ensure that all information provided matches your government-issued ID to avoid verification issues.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Section
                    Text(
                      'Personal Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // First Name
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Middle Name (Optional)
                    _buildTextField(
                      controller: _middleNameController,
                      label: 'Middle Name (Optional)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Text(
                      'Gender',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildGenderOption('Male', Icons.male),
                        const SizedBox(width: 16),
                        _buildGenderOption('Female', Icons.female),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Birthdate
                    _buildTextField(
                      controller: _birthdateController,
                      label: 'Date of Birth',
                      icon: Icons.cake,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Skills Section
                    Text(
                      'Specialization',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select your specialization',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      debugPrint('Building SearchableDropdown with:');
                      debugPrint('- allSkills length: ${_allSkills.length}');
                      debugPrint(
                          '- selectedSkills length: ${_selectedSkills.length}');
                      debugPrint('- isLoadingSkills: $_isLoadingSkills');

                      // If there are no skills or we're still loading, show a simple dropdown with loading indicator
                      if (_isLoadingSkills) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.work, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Loading specializations...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // If we have no skills, show an error message
                      if (_allSkills.isEmpty) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No specializations available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadSkills,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0272B1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Use a simple dropdown that will definitely work
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.work, color: Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF0272B1), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                        ),
                        hint: Text(
                          'Select specialization',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        isExpanded: true,
                        value: _selectedSpecializationId != null
                            ? _allSkills.any((skill) =>
                                    skill['id'].toString() ==
                                    _selectedSpecializationId.toString())
                                ? _selectedSpecializationId.toString()
                                : null
                            : null,
                        items: _allSkills
                            .map((skill) {
                              // Make sure each item has a unique ID
                              final String id = skill['id']?.toString() ?? '';
                              if (id.isEmpty) {
                                debugPrint(
                                    'GeneralInfoPage: Warning - Skill missing ID: ${skill['name']}');
                                return null;
                              }

                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  skill['name']?.toString() ?? 'Unknown',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<String>>()
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            final selectedSkill = _allSkills.firstWhere(
                              (skill) => skill['id'].toString() == value,
                              orElse: () => {'id': '', 'name': ''},
                            );

                            setState(() {
                              _selectedSkills = [selectedSkill];
                              _skillsController.text =
                                  selectedSkill['name'].toString();
                              _selectedSpecializationId = int.tryParse(value);
                              debugPrint(
                                  'GeneralInfoPage: Selected specialization ID: $_selectedSpecializationId, name: ${_skillsController.text}');
                            });
                          }
                        },
                      );
                    }),

                    const SizedBox(height: 8),
                    Text(
                      'Please select your primary area of expertise',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // After the specialization section, add the pay period and wage section
                    const SizedBox(height: 24),

                    // Pay Period and Wage Section
                    Text(
                      'Compensation Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pay Period Dropdown
                    Text(
                      'Pay Period',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon:
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0272B1), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
                      value: _payPeriod,
                      items: _payPeriodOptions.map((String period) {
                        return DropdownMenuItem<String>(
                          value: period,
                          child: Text(
                            period,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _payPeriod = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Wage Field
                    _buildTextField(
                      controller: _wageController,
                      label: 'Wage (₱)',
                      icon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your wage';
                        }
                        final double? wage = double.tryParse(value);
                        if (wage == null || wage <= 0) {
                          return 'Please enter a valid wage amount';
                        }
                        return null;
                      },
                      hintText: 'Enter your ${_payPeriod.toLowerCase()} rate',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getWageHelperText(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact Information Section
                    Text(
                      'Contact Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        final bool emailValid = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value);

                        if (!emailValid) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone number
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Address Section
                    Text(
                      'Address Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region
                    Text(
                      'Region',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedRegion != null &&
                              _selectedRegion is Map<String, dynamic>
                          ? _selectedRegion!['code']
                          : null,
                      items: _regions,
                      hintText: 'Select Region',
                      icon: Icons.location_on,
                      validator: (value) =>
                          value == null ? 'Please select a region' : null,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          final selectedRegion = _regions.firstWhere(
                              (region) => region['code'] == newValue);
                          setState(() {
                            _selectedRegion = selectedRegion;
                            _selectedProvince = null;
                            _selectedCity = null;
                            _selectedBarangay = null;
                            _loadProvinces(newValue);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Province
                    Text(
                      'Province',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedProvince != null
                          ? _selectedProvince!['code']
                          : null,
                      items: _provinces,
                      hintText: 'Select Province',
                      icon: Icons.location_city,
                      validator: (value) =>
                          value == null ? 'Please select a province' : null,
                      onChanged: _selectedRegion == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedProvince = _provinces.firstWhere(
                                    (province) => province['code'] == newValue);
                                setState(() {
                                  _selectedProvince = selectedProvince;
                                  _selectedCity = null;
                                  _selectedBarangay = null;
                                  _loadCities(newValue);
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // City/Municipality
                    Text(
                      'City/Municipality',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value:
                          _selectedCity != null ? _selectedCity!['code'] : null,
                      items: _cities,
                      hintText: 'Select City/Municipality',
                      icon: Icons.location_city,
                      validator: (value) => value == null
                          ? 'Please select a city or municipality'
                          : null,
                      onChanged: _selectedProvince == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedCity = _cities.firstWhere(
                                    (city) => city['code'] == newValue);
                                setState(() {
                                  _selectedCity = selectedCity;
                                  _selectedBarangay = null;
                                  _loadBarangays(newValue);
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Barangay
                    Text(
                      'Barangay',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdown(
                      value: _selectedBarangay != null
                          ? _selectedBarangay!['code']
                          : null,
                      items: _barangays,
                      hintText: 'Select Barangay',
                      icon: Icons.holiday_village,
                      validator: (value) =>
                          value == null ? 'Please select a barangay' : null,
                      onChanged: _selectedCity == null
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                final selectedBarangay = _barangays.firstWhere(
                                    (brgy) => brgy['code'] == newValue);
                                setState(() {
                                  _selectedBarangay = selectedBarangay;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Street Address
                    _buildTextField(
                      controller: _streetAddressController,
                      label: 'Street Address (House/Lot/Blk/Unit No.)',
                      icon: Icons.home,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Postal Code
                    _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal/ZIP Code',
                      icon: Icons.markunread_mailbox,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your postal code';
                        }
                        if (value.length < 4) {
                          return 'Please enter a valid postal code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Continue to ID Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0272B1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText,
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[800],
      ),
      isExpanded: true,
      hint: Text(
        hintText,
        style: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
      validator: validator,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
        return DropdownMenuItem<String>(
          value: item['code'],
          child: Text(item['name']),
        );
      }).toList(),
    );
  }

  Widget _buildGenderOption(String gender, IconData genderIcon) {
    final bool isSelected = _gender == gender;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = gender;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0272B1).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0272B1) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                genderIcon,
                color: isSelected ? const Color(0xFF0272B1) : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF0272B1) : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get wage helper text based on pay period
  String _getWageHelperText() {
    switch (_payPeriod) {
      case 'Hourly':
        return 'Enter your hourly rate (e.g., 150 for ₱150 per hour)';
      case 'Daily':
        return 'Enter your daily rate (e.g., 1000 for ₱1,000 per day)';
      case 'Weekly':
        return 'Enter your weekly rate (e.g., 5000 for ₱5,000 per week)';
      case 'Bi-weekly':
        return 'Enter your bi-weekly rate (e.g., 10000 for ₱10,000 every two weeks)';
      case 'Monthly':
        return 'Enter your monthly rate (e.g., 20000 for ₱20,000 per month)';
      default:
        return 'Enter your wage rate';
    }
  }
}
