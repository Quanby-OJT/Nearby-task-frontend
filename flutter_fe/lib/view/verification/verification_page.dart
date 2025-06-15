import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/view/verification/face_detection_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/model/verification_model.dart';
import 'package:flutter_fe/service/api_service.dart';

// Import separate verification pages
import 'general_info_page.dart';
import 'id_verification_page.dart';
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
  String? _userRole;

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
      debugPrint('VerificationPage: Retrieved user_id from storage: $userId');
      debugPrint('VerificationPage: user_id type: ${userId.runtimeType}');

      if (userId != null) {
        final parsedUserId = int.parse(userId.toString());
        debugPrint('VerificationPage: Parsed user_id: $parsedUserId');

        final result =
            await ApiService.getTaskerVerificationStatus(parsedUserId);

        debugPrint(
            'Verification status check result: ${jsonEncode(result['verification'])}');

        if (result['success'] == true && result['exists'] == true) {
          // User has existing verification data
          if (result['verification'] != null) {
            final verificationData =
                VerificationModel.fromJson(result['verification']);
            debugPrint(
                'VerificationPage: Existing verification data status: ${verificationData.status}');
            debugPrint(
                'VerificationPage: Raw verification result: ${jsonEncode(result['verification'])}');

            setState(() {
              _existingVerification = verificationData;
              _verificationStatus = verificationData.status;
              _isUpdateMode = true;

              debugPrint(
                  'VerificationPage: Set _verificationStatus to: $_verificationStatus');

              // Pre-populate data
              if (verificationData.idImageUrl != null) {
                _isIdVerified = true;
                _idType = verificationData.idType;
              }

              if (verificationData.selfieImageUrl != null) {
                _isSelfieVerified = true;
              }

              if (verificationData.documentUrl != null ||
                  verificationData.clientDocumentUrl != null) {
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
            if (_verificationStatus == 'Active') {
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
            } else if (_verificationStatus == 'Review') {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Your verification is pending review. You can update your information.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.amber,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      duration: Duration(seconds: 3),
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
                        "Your verification was rejected. Please update your information and resubmit.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      duration: Duration(seconds: 3),
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
        debugPrint(
            'VerificationPage: Skipping user data load - already have verification data');
        return;
      }

      _userRole = await storage.read('role');
      debugPrint("Role from session: ${storage.read('role')}");

      final userIdFromStorage = storage.read('user_id');

      int userId = int.parse(userIdFromStorage.toString());

      final user = await _controller.getAuthenticatedUser(userId);
      debugPrint('VerificationPage: _loadUserData - received user: $user');

      if (user != null) {
      } else {
        debugPrint('VerificationPage: _loadUserData - user is null!');
      }
    } catch (error) {
      debugPrint('Error loading user data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error loading user data. Please try again.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: Duration(seconds: 3),
          ),
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

  void _onSelfieVerified(File? selfieImage) {
    setState(() {
      // Only set _selfieImage if a new file was provided
      // If null, it means user approved existing selfie
      if (selfieImage != null) {
        _selfieImage = selfieImage;
      }
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
      _showExitConfirmationDialog();
    }
  }

  // Show confirmation dialog when user tries to exit verification
  Future<void> _showExitConfirmationDialog() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Exit Verification?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to exit the verification process?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'If you exit now:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildWarningPoint('Your progress will be saved'),
                    _buildWarningPoint('You can continue later'),
                    if (!_isUpdateMode)
                      _buildWarningPoint('Verification will remain incomplete'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Continue Verification',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB71A4A),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Exit',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      Navigator.of(context).pop();
    }
  }

  // Helper method to build warning points
  Widget _buildWarningPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerification() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Get the current user ID
      final userId = int.parse(storage.read('user_id').toString());
      _userRole = storage.read('role');

      // Prepare the complete verification data
      final verificationData = {
        // User basic information
        "firstName": _userInfo['firstName'] ?? '',
        "middleName": _userInfo['middleName'] ?? '',
        "lastName": _userInfo['lastName'] ?? '',
        "email": _userInfo['email'] ?? '',
        "phone": _userInfo['phone'] ?? '',
        "gender": _userInfo['gender'] ?? '',
        "birthdate": _userInfo['birthdate'] ?? '',
        "bio": _userInfo['bio'] ?? '',
        "socialMediaJson": _userInfo['socialMediaJson'] ?? '{}',
      };

      debugPrint(
          'VerificationPage: Submitting verification for role: $_userRole');
      debugPrint('VerificationPage: Verification data: $verificationData');

      Map<String, dynamic> result;

      // Submit based on user role to appropriate table
      if (_userRole?.toLowerCase() == 'tasker') {
        // Add tasker-specific fields
        verificationData.addAll({
          "specializationId": _userInfo['specializationId'],
          "skills": _userInfo['skills'] ?? '',
          "wagePerHour": _userInfo['wage'],
          "payPeriod": _userInfo['payPeriod'] ?? 'Hourly',
          "availability": _userInfo['availability'] ?? true,
        });

        // Submit to tasker table
        result = await ApiService.submitTaskerVerificationNew(
          userId,
          verificationData,
          _idImage,
          _selfieImage,
          _documentFile,
        );
      } else if (_userRole?.toLowerCase() == 'client') {
        // Add client-specific fields
        verificationData.addAll({
          "preferences": _userInfo['preferences'] ?? '',
          "clientAddress": _userInfo['clientAddress'] ?? '',
        });

        // Submit to client table
        result = await ApiService.submitClientVerification(
          userId,
          verificationData,
          _idImage,
          _selfieImage,
          _documentFile,
        );
      } else {
        throw Exception('Unknown user role: $_userRole');
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
            content: Text(
              "Verification submitted successfully! Your information will be reviewed shortly.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: Duration(seconds: 3),
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
            content: Text(
              "Failed to submit verification. Please try again.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      debugPrint('Error submitting verification: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error while ${_isUpdateMode ? 'updating' : 'submitting'} verification. Please Try Again. If the problem persists. Contact our support.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle device back button press
        if (_currentPageIndex > 0) {
          _pageController.animateToPage(
            _currentPageIndex - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false; // Prevent default back navigation
        } else {
          // Show exit confirmation dialog
          final bool? shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exit Verification?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to exit the verification process?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'If you exit now:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWarningPoint('Your progress will be saved'),
                          _buildWarningPoint('You can continue later'),
                          if (!_isUpdateMode)
                            _buildWarningPoint(
                                'Verification will remain incomplete'),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Continue Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB71A4A),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Exit',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          return shouldExit ?? false; // Return the user's choice
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isUpdateMode
              ? 'Update ${_pageTitles[_currentPageIndex]}'
              : _pageTitles[_currentPageIndex]),
          backgroundColor: const Color(0xFFB71A4A),
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
                  FaceDetectionPage(
                    onDetectionComplete: (file, isValid) =>
                        _onSelfieVerified(file),
                  ),

                  // Page 4: Document Upload (Optional)
                  DocumentUploadPage(
                    onDocumentUploaded: _onDocumentUploaded,
                  ),
                ],
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
                    backgroundColor: const Color(0xFFB71A4A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isUpdateMode
                        ? "Update Information"
                        : "Submit Verification",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
