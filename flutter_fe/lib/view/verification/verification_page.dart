import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/model/verification_model.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Import separate verification pages
import 'general_info_page.dart';
import 'id_verification_page.dart';
import 'selfie_verification_page.dart';
import 'document_upload_page.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final ProfileController _controller = ProfileController();
  final GetStorage storage = GetStorage();

  // Status tracking
  bool _isGeneralInfoCompleted = false;
  bool _isIdVerified = false;
  bool _isSelfieVerified = false;
  bool _isDocumentsUploaded = false;
  bool _isLoading = false;
  bool _isUpdateMode = false;
  String? _verificationStatus;
  VerificationModel? _existingVerification;

  // User information
  Map<String, dynamic> _userInfo = {};

  // Files
  File? _idImage;
  String? _idType;
  File? _selfieImage;
  File? _documentFile;

  // Page controller
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPageIndex = 0;
  final List<String> _pageTitles = [
    'General Information',
    'ID Verification',
    'Selfie Verification',
    'Document Upload'
  ];

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _checkVerificationStatus().then((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final result = await ApiService.getTaskerVerificationStatus(
            int.parse(userId.toString()));

        debugPrint('Verification status check result: ${jsonEncode(result)}');

        if (result['success'] == true && result['exists'] == true) {
          // User has existing verification data
          if (result['verification'] != null) {
            final verificationData =
                VerificationModel.fromJson(result['verification']);

            setState(() {
              _existingVerification = verificationData;
              _verificationStatus = verificationData.status;
              _isUpdateMode = true;

              // Pre-populate data
              if (verificationData.idImageUrl != null) {
                _isIdVerified = true;
                _idType = verificationData.idType;
              }

              if (verificationData.selfieImageUrl != null) {
                _isSelfieVerified = true;
              }

              if (verificationData.documentUrl != null) {
                _isDocumentsUploaded = true;
              }

              // Pre-populate user info
              _userInfo = {
                'firstName': verificationData.firstName,
                'middleName': verificationData.middleName,
                'lastName': verificationData.lastName,
                'email': verificationData.email,
                'phone': verificationData.phone,
                'gender': verificationData.gender,
                'birthdate': verificationData.birthdate,
                'bio': verificationData.bio,
                'socialMediaJson': verificationData.socialMediaJson,
              };

              _isGeneralInfoCompleted = true;
            });

            // Show appropriate message based on verification status
            if (_verificationStatus == 'approved') {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Your account is already verified. You can update your information.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              });
            } else if (_verificationStatus == 'pending') {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Your verification is pending review. You can update your information.'),
                      backgroundColor: Colors.amber,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              });
            } else if (_verificationStatus == 'rejected') {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Your verification was rejected. Please update your information and resubmit.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // If we already have user info from verification data, skip this step
      if (_isGeneralInfoCompleted && _userInfo.isNotEmpty) {
        return;
      }

      int userId = int.parse(storage.read('user_id').toString());
      await _controller.getAuthenticatedUser(context, userId);
    } catch (error) {
      debugPrint('Error loading user data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $error')),
        );
      }
    }
  }

  void _onGeneralInfoCompleted(Map<String, dynamic> userInfo) {
    setState(() {
      _userInfo = userInfo;
      _isGeneralInfoCompleted = true;

      // Log the user info for debugging
      debugPrint('VerificationPage: General info completed');
      debugPrint('VerificationPage: User info: ${_userInfo.toString()}');

      // Log the pay period and wage specifically
      debugPrint('VerificationPage: Pay Period: ${_userInfo['payPeriod']}');
      debugPrint('VerificationPage: Wage: ${_userInfo['wage']}');

      // Log social media links JSON
      if (_userInfo.containsKey('socialMediaJson')) {
        final String socialMediaJson = _userInfo['socialMediaJson'] as String;
        debugPrint(
            'VerificationPage: Social Media Links JSON: $socialMediaJson');

        // Parse the JSON to show individual links for debugging
        try {
          final Map<String, dynamic> socialMediaLinks =
              jsonDecode(socialMediaJson);
          debugPrint('VerificationPage: Social Media Links (parsed):');
          socialMediaLinks.forEach((platform, url) {
            debugPrint('  - $platform: $url');
          });
        } catch (e) {
          debugPrint('VerificationPage: Error parsing social media JSON: $e');
        }
      }

      _navigateToNextPage();
    });
  }

  void _onIdVerified(File idImage, String idType) {
    setState(() {
      _idImage = idImage;
      _idType = idType;
      _isIdVerified = true;
      _navigateToNextPage();
    });
  }

  void _onSelfieVerified(File selfieImage) {
    setState(() {
      _selfieImage = selfieImage;
      _isSelfieVerified = true;
      _navigateToNextPage();
    });
  }

  void _onDocumentUploaded(File? documentFile) {
    setState(() {
      _documentFile = documentFile;
      _isDocumentsUploaded = true;
      _submitVerification();
    });
  }

  void _navigateToNextPage() {
    if (_currentPageIndex < 3) {
      _pageController.animateToPage(
        _currentPageIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.animateToPage(
        _currentPageIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitVerification() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Get the current user ID
      final userId = int.parse(storage.read('user_id').toString());

      // Prepare the verification data using the VerificationModel
      final verificationData = VerificationModel(
        userId: userId,
        firstName: _userInfo['firstName'],
        middleName: _userInfo['middleName'],
        lastName: _userInfo['lastName'],
        email: _userInfo['email'],
        phone: _userInfo['phone'],
        gender: _userInfo['gender'],
        birthdate: _userInfo['birthdate'],
        specialization: _userInfo['specialization'] ?? '',
        specializationId: _userInfo['specializationId'],
        payPeriod: _userInfo['payPeriod'] ?? 'Hourly',
        wage: _userInfo['wage'] ?? 0.0,
        socialMediaJson: _userInfo['socialMediaJson'],
        idType: _idType,
        status: _verificationStatus ?? 'pending',
        verificationDate: DateTime.now().toIso8601String(),
        bio: _userInfo['bio'],
      );

      // Log the verification data for debugging
      debugPrint('VerificationPage: Submitting verification');
      debugPrint(
          'VerificationPage: Verification data: ${verificationData.toJson()}');
      debugPrint('VerificationPage: Is update mode: $_isUpdateMode');

      // Submit verification using the appropriate method
      Map<String, dynamic> result;

      if (_isUpdateMode) {
        // Update existing verification
        result = await ApiService.submitTaskerVerificationWithNewTable(
          userId,
          verificationData.toJson(),
          _idImage,
          _selfieImage,
          _documentFile,
        );
      } else {
        // Submit new verification
        result = await ApiService.submitTaskerVerificationWithNewTable(
          userId,
          verificationData.toJson(),
          _idImage,
          _selfieImage,
          _documentFile,
        );
      }

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Check if submission was successful
      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isUpdateMode
                ? (result['message'] ??
                    'Your information has been updated successfully!')
                : (result['message'] ??
                    'Verification submitted successfully! We will review your information and notify you once verified.')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ??
                (_isUpdateMode
                    ? 'Failed to update information'
                    : 'Failed to submit verification')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      debugPrint('Error submitting verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${_isUpdateMode ? 'updating' : 'submitting'} verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdateMode
            ? 'Update ${_pageTitles[_currentPageIndex]}'
            : _pageTitles[_currentPageIndex]),
        backgroundColor: const Color(0xFF0272B1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToPreviousPage,
        ),
      ),
      body: Stack(
        children: [
          // Verification Status Banner (if verified)
          if (_verificationStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _verificationStatus == 'approved'
                  ? Colors.green[50]
                  : _verificationStatus == 'rejected'
                      ? Colors.red[50]
                      : Colors.amber[50],
              child: Row(
                children: [
                  Icon(
                    _verificationStatus == 'approved'
                        ? Icons.check_circle
                        : _verificationStatus == 'rejected'
                            ? Icons.cancel
                            : Icons.pending,
                    color: _verificationStatus == 'approved'
                        ? Colors.green
                        : _verificationStatus == 'rejected'
                            ? Colors.red
                            : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _verificationStatus == 'approved'
                          ? 'Your account is verified. You can update your information.'
                          : _verificationStatus == 'rejected'
                              ? 'Your verification was rejected. Please update your information.'
                              : 'Your verification is pending review.',
                      style: TextStyle(
                        color: _verificationStatus == 'approved'
                            ? Colors.green[800]
                            : _verificationStatus == 'rejected'
                                ? Colors.red[800]
                                : Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Padding(
            padding: EdgeInsets.only(
              top: _verificationStatus != null ? 40.0 : 0.0,
            ),
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevent swiping between pages
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                // Page 1: General Information
                GeneralInfoPage(
                  onInfoCompleted: _onGeneralInfoCompleted,
                ),

                // Page 2: ID Verification
                IdVerificationPage(
                  onIdVerified: _onIdVerified,
                ),

                // Page 3: Selfie Verification
                SelfieVerificationPage(
                  onSelfieVerified: _onSelfieVerified,
                ),

                // Page 4: Document Upload (Optional)
                DocumentUploadPage(
                  onDocumentUploaded: _onDocumentUploaded,
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isUpdateMode
                          ? 'Updating your information...'
                          : 'Submitting verification...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _currentPageIndex == 3 && !_isDocumentsUploaded
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isDocumentsUploaded = true;
                    _submitVerification();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0272B1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isUpdateMode ? "Update Information" : "Submit Verification",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
