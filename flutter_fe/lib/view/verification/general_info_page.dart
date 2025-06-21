import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class GeneralInfoPage extends StatefulWidget {
  final Function(Map<String, dynamic> userInfo) onInfoCompleted;

  const GeneralInfoPage({super.key, required this.onInfoCompleted});

  @override
  State<GeneralInfoPage> createState() => _GeneralInfoPageState();
}

class _GeneralInfoPageState extends State<GeneralInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final GetStorage storage = GetStorage();
  final ProfileController _profileController = ProfileController();
  final JobPostService _jobPostService = JobPostService();
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  // Form data
  String? _gender;
  DateTime? _birthdate;
  bool _isLoading = false;
  final bool _isUploadingImage = false;
  String? _userRole;
  File? _profileImage;
  String? _uploadedImageUrl;
  String? _existingImageUrl; // For displaying existing image from tasker_images

  // Specialization data
  final List<SpecializationModel> _specializations = [];
  SpecializationModel? _selectedSpecialization;
  final bool _isLoadingSpecializations = false;

  // Pay period data
  final String _selectedPayPeriod = 'Hourly';
  final List<String> _payPeriods = [
    'Hourly',
    'Daily',
    'Weekly',
    'Monthly',
    'Per Project'
  ];

  @override
  void initState() {
    super.initState();
    _isLoading = true;

    Future.microtask(() {
      _loadUserData();
      //_loadSpecializations();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user ID from storage
      final userId = storage.read('user_id');
      debugPrint(
          'Retrieved user_id from storage: $userId (type: ${userId.runtimeType})');

      if (userId != null) {
        final parsedUserId = int.parse(userId.toString());
        debugPrint('Parsed user_id: $parsedUserId');

        // Fetch authenticated user data from API
        final AuthenticatedUser? authUser = await _profileController
            .getAuthenticatedUser(context, parsedUserId);

        if (authUser != null && mounted) {
          debugPrint(
              'AuthUser data: ${authUser.user.id}, role: ${authUser.user.role}');

          // Populate form fields with user data
          setState(() {
            // Store user role for conditional UI
            _userRole = authUser.user.role;

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
          });

          // Fetch existing profile image for both taskers and clients
          if (authUser.user.role.toLowerCase() == 'tasker' ||
              authUser.user.role.toLowerCase() == 'client') {
            // Use authUser.user.id if it's valid, otherwise use the original userId from storage
            final userIdToUse =
                (authUser.user.id != null && authUser.user.id! > 0)
                    ? authUser.user.id!
                    : parsedUserId;
            debugPrint(
                'Using user ID for image fetch: $userIdToUse (authUser.user.id: ${authUser.user.id}, storage userId: $parsedUserId)');
            await _fetchExistingProfileImage(userIdToUse);
          }
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

  Future<void> _fetchExistingProfileImage(int userId) async {
    try {
      debugPrint('Fetching existing profile image for user ID: $userId');
      debugPrint('User role: $_userRole');

      Map<String, dynamic> result;

      if (_userRole?.toLowerCase() == 'tasker') {
        final taskerService = TaskerService();
        result = await taskerService.getTaskerImages(userId);
      } else if (_userRole?.toLowerCase() == 'client') {
        final clientService = ClientServices();
        result = await clientService.getClientImages(userId);
      } else {
        debugPrint('Unknown user role for fetching profile image: $_userRole');
        return;
      }

      debugPrint('Profile image fetch result: $result');

      if (result.containsKey('images') && result['images'] is List) {
        final List<dynamic> images = result['images'];
        if (images.isNotEmpty) {
          final firstImage = images.first;
          if (firstImage is Map && firstImage['image_link'] != null) {
            setState(() {
              _existingImageUrl = firstImage['image_link'];
            });
            debugPrint('✅ Found existing profile image: $_existingImageUrl');
          }
        } else {
          debugPrint('No existing profile images found');
        }
      }
    } catch (e) {
      debugPrint('Error fetching existing profile image: $e');
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
              primary: Color(0xFFB71A4A),
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

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          // Clear any previously uploaded URL since we have a new image
          _uploadedImageUrl = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture selected. It will be uploaded when you submit verification.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting image. Please try again.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitInfo() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> userInfo = {
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'birthdate': _birthdate != null
            ? DateFormat('yyyy-MM-dd').format(_birthdate!)
            : null,
        'profileImage': _profileImage, // Pass the image file instead of URL
      };

      widget.onInfoCompleted(userInfo);
    }
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
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB71A4A),
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

                    // Profile Picture Section
                    if (_userRole?.toLowerCase() == 'tasker' ||
                        _userRole?.toLowerCase() == 'client') ...[
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Profile Picture',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(60),
                                  border: Border.all(
                                    color: const Color(0xFFB71A4A),
                                    width: 2,
                                  ),
                                ),
                                child: _profileImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(58),
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _existingImageUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(58),
                                            child: Image.network(
                                              _existingImageUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Color(0xFFB71A4A),
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                debugPrint(
                                                    'Error loading existing profile image: $error');
                                                return const Icon(
                                                  Icons.add_a_photo,
                                                  size: 50,
                                                  color: Color(0xFFB71A4A),
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.add_a_photo,
                                            size: 50,
                                            color: Color(0xFFB71A4A),
                                          ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _profileImage != null
                                  ? 'Tap to change profile picture'
                                  : _existingImageUrl != null
                                      ? 'Tap to change profile picture'
                                      : 'Tap to add profile picture',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_profileImage != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'New Image Selected ✓',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else if (_existingImageUrl != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Current Profile Image',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

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

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71A4A),
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
                color: Color(0xFFB71A4A),
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
                ? const Color(0xFFB71A4A).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFB71A4A) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                genderIcon,
                color: isSelected ? const Color(0xFFB71A4A) : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFFB71A4A) : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
