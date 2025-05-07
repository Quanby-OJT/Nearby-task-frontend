import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';

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
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
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

      // Prepare the verification data
      Map<String, dynamic> verificationData = {
        ..._userInfo,
        'id_verified': _isIdVerified,
        'selfie_verified': _isSelfieVerified,
        'documents_uploaded': _isDocumentsUploaded,
        'verification_status': 'pending',
        'verification_date': DateTime.now().toIso8601String(),
      };

      // Log the verification data for debugging
      debugPrint('VerificationPage: Submitting verification');
      debugPrint('VerificationPage: Verification data: $verificationData');

      // Mock implementation - replace with actual API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Verification submitted successfully! We will review your information and notify you once verified.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate back after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      debugPrint('Error submitting verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: ${e.toString()}'),
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
        title: Text(_pageTitles[_currentPageIndex]),
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
          PageView(
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

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Submitting verification...',
                      style: TextStyle(
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
    );
  }
}
