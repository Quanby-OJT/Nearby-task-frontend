import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
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
  final ProfileController _profileController = ProfileController();
  final JobPostService _jobPostService = JobPostService();

  // Text controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();

  // Social media controllers
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  // Form data
  String? _gender;
  DateTime? _birthdate;
  bool _isLoading = false;
  String? _userRole;

  // Specialization data
  List<SpecializationModel> _specializations = [];
  SpecializationModel? _selectedSpecialization;
  bool _isLoadingSpecializations = false;

  // Pay period data
  String _selectedPayPeriod = 'Hourly';
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
      _loadSpecializations();
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
    _bioController.dispose();
    _skillsController.dispose();
    _wageController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user ID from storage
      final userId = storage.read('user_id');
      if (userId != null) {
        // Fetch authenticated user data from API
        final AuthenticatedUser? authUser = await _profileController
            .getAuthenticatedUser(int.parse(userId.toString()));

        if (authUser != null && mounted) {
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

            // Set bio if available in user model
            if (authUser.user.bio != null && authUser.user.bio!.isNotEmpty) {
              _bioController.text = authUser.user.bio!;
            }

            // Set tasker-specific data if available
            if (authUser.tasker != null) {
              if (authUser.tasker!.skills != null &&
                  authUser.tasker!.skills!.isNotEmpty) {
                _skillsController.text = authUser.tasker!.skills!;
              }

              if (authUser.tasker!.wagePerHour != null) {
                _wageController.text = authUser.tasker!.wagePerHour.toString();
              }

              if (authUser.tasker!.payPeriod != null &&
                  authUser.tasker!.payPeriod!.isNotEmpty) {
                _selectedPayPeriod = authUser.tasker!.payPeriod!;
              }

              // Set selected specialization if available
              if (authUser.tasker!.specializationId != null) {
                // Find matching specialization from loaded list
                for (var spec in _specializations) {
                  if (spec.id == authUser.tasker!.specializationId) {
                    _selectedSpecialization = spec;
                    break;
                  }
                }
              }
            }

            // Set social media links if available in user model
            if (authUser.user.socialMediaLinks != null &&
                authUser.user.socialMediaLinks!.isNotEmpty) {
              final socialLinks = authUser.user.socialMediaLinks!;

              if (socialLinks.containsKey('facebook')) {
                _facebookController.text = socialLinks['facebook']!;
              }

              if (socialLinks.containsKey('instagram')) {
                _instagramController.text = socialLinks['instagram']!;
              }

              if (socialLinks.containsKey('linkedin')) {
                _linkedinController.text = socialLinks['linkedin']!;
              }

              if (socialLinks.containsKey('twitter')) {
                _twitterController.text = socialLinks['twitter']!;
              }
            } else {
              // Try to parse social media links from JSON string if stored that way
              try {
                final String socialMediaJson =
                    storage.read('social_media_links') ?? '{}';
                if (socialMediaJson != '{}') {
                  final Map<String, dynamic> socialLinks =
                      jsonDecode(socialMediaJson);

                  if (socialLinks.containsKey('facebook')) {
                    _facebookController.text = socialLinks['facebook'];
                  }

                  if (socialLinks.containsKey('instagram')) {
                    _instagramController.text = socialLinks['instagram'];
                  }

                  if (socialLinks.containsKey('linkedin')) {
                    _linkedinController.text = socialLinks['linkedin'];
                  }

                  if (socialLinks.containsKey('twitter')) {
                    _twitterController.text = socialLinks['twitter'];
                  }
                }
              } catch (e) {
                debugPrint('Error parsing social media links: $e');
              }
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

  Future<void> _loadSpecializations() async {
    try {
      setState(() {
        _isLoadingSpecializations = true;
      });

      debugPrint('GeneralInfoPage: Loading specializations...');
      final specializations = await _jobPostService.getSpecializations();

      if (mounted) {
        setState(() {
          _specializations = specializations;
          _isLoadingSpecializations = false;
        });

        debugPrint(
            'GeneralInfoPage: Loaded ${specializations.length} specializations');
      }
    } catch (e) {
      debugPrint('GeneralInfoPage: Error loading specializations: $e');
      if (mounted) {
        setState(() {
          _isLoadingSpecializations = false;
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

  void _submitInfo() {
    if (_formKey.currentState!.validate()) {
      // Additional validation for tasker-specific fields
      // if (_userRole?.toLowerCase() == 'tasker') {
      //   if (_selectedSpecialization == null) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Please select a specialization'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //     return;
      //   }
      //
      //   if (_wageController.text.trim().isEmpty) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Please enter your hourly wage'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //     return;
      //   }
      //
      //   double? wage = double.tryParse(_wageController.text.trim());
      //   if (wage == null || wage <= 0) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Please enter a valid wage amount'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //     return;
      //   }
      // }
      //
      // // Create social media links object
      // Map<String, String> socialMediaLinks = {
      //   'facebook': _facebookController.text.trim(),
      //   'instagram': _instagramController.text.trim(),
      //   'linkedin': _linkedinController.text.trim(),
      //   'twitter': _twitterController.text.trim(),
      // };
      //
      // // Remove empty values
      // socialMediaLinks.removeWhere((key, value) => value.isEmpty);
      //
      // // Convert to JSON string for storage
      // String socialMediaJson = jsonEncode(socialMediaLinks);

      // Create user info object
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
        //'socialMediaJson': socialMediaJson,
        'bio': _bioController.text.trim(),
        //'socialMediaLinks': socialMediaLinks,
      };

      // Add tasker-specific fields if user is a tasker
      if (_userRole?.toLowerCase() == 'tasker') {
        userInfo.addAll({
          'specializationId': _selectedSpecialization?.id,
          'skills': _skillsController.text.trim(),
          'payPeriod': _selectedPayPeriod,
          'wage': double.parse(_wageController.text.trim()),
          'availability': true, // Default to available
        });
      } else {
        // For client users, add default values
        userInfo.addAll({
          'payPeriod': 'Hourly',
          'wage': 0.0,
        });
      }

      // Save to storage for future reference
      //storage.write('bio', _bioController.text.trim());
      //storage.write('social_media_links', socialMediaJson);

      // Call the callback function with the user info
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
                    // Header
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

                    ///
                    /// All of this text fields were moved to profile.
                    ///
                    /// -Ces
                    ///
                    // Bio Section
                    // Text(
                    //   'Professional Bio',
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.grey[800],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // Bio Text Field
                    // _buildTextField(
                    //   controller: _bioController,
                    //   label: 'Tell us about yourself and your skills',
                    //   icon: Icons.person_outline,
                    //   maxLines: 4,
                    //   keyboardType: TextInputType.multiline,
                    //   hintText:
                    //       'Share your experience, skills, and what you can offer to clients',
                    // ),
                    // const SizedBox(height: 8),
                    // Text(
                    //   'Your bio will be visible to potential clients',
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 12,
                    //     fontStyle: FontStyle.italic,
                    //     color: Colors.grey[600],
                    //   ),
                    // ),

                    // Social Media Links Section
                    // Text(
                    //   'Social Media Links (Optional)',
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.grey[800],
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Text(
                    //   'Add your social media profiles to enhance your verification',
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 14,
                    //     color: Colors.grey[600],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // Facebook
                    // _buildTextField(
                    //   controller: _facebookController,
                    //   label: 'Facebook Profile URL',
                    //   icon: Icons.facebook,
                    //   keyboardType: TextInputType.url,
                    //   hintText: 'https://facebook.com/yourusername',
                    //   validator: (value) {
                    //     if (value != null && value.isNotEmpty) {
                    //       if (!value.contains('facebook.com')) {
                    //         return 'Please enter a valid Facebook URL';
                    //       }
                    //     }
                    //     return null; // Optional field
                    //   },
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // Instagram
                    // _buildTextField(
                    //   controller: _instagramController,
                    //   label: 'Instagram Profile URL',
                    //   icon: Icons.camera_alt,
                    //   keyboardType: TextInputType.url,
                    //   hintText: 'https://instagram.com/yourusername',
                    //   validator: (value) {
                    //     if (value != null && value.isNotEmpty) {
                    //       if (!value.contains('instagram.com')) {
                    //         return 'Please enter a valid Instagram URL';
                    //       }
                    //     }
                    //     return null; // Optional field
                    //   },
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // LinkedIn
                    // _buildTextField(
                    //   controller: _linkedinController,
                    //   label: 'LinkedIn Profile URL',
                    //   icon: Icons.business_center,
                    //   keyboardType: TextInputType.url,
                    //   hintText: 'https://linkedin.com/in/yourusername',
                    //   validator: (value) {
                    //     if (value != null && value.isNotEmpty) {
                    //       if (!value.contains('linkedin.com')) {
                    //         return 'Please enter a valid LinkedIn URL';
                    //       }
                    //     }
                    //     return null; // Optional field
                    //   },
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // Twitter
                    // _buildTextField(
                    //   controller: _twitterController,
                    //   label: 'Twitter Profile URL',
                    //   icon: Icons.chat,
                    //   keyboardType: TextInputType.url,
                    //   hintText: 'https://twitter.com/yourusername',
                    //   validator: (value) {
                    //     if (value != null && value.isNotEmpty) {
                    //       if (!value.contains('twitter.com') &&
                    //           !value.contains('x.com')) {
                    //         return 'Please enter a valid Twitter/X URL';
                    //       }
                    //     }
                    //     return null; // Optional field
                    //   },
                    // ),
                    // const SizedBox(height: 24),

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
