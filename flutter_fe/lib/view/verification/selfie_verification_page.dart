import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/model/verification_model.dart';

class SelfieVerificationPage extends StatefulWidget {
  final Function(File selfieImage) onSelfieVerified;

  const SelfieVerificationPage({super.key, required this.onSelfieVerified});

  @override
  State<SelfieVerificationPage> createState() => _SelfieVerificationPageState();
}

class _SelfieVerificationPageState extends State<SelfieVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final storage = GetStorage();

  File? _selfieImage;
  String? _selfieImageName;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _selfieImageUrl;
  String? _verificationStatus;
  VerificationModel? _verificationData;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final result = await ApiService.getTaskerVerificationStatus(
            int.parse(userId.toString()));

        debugPrint('Verification API response: ${jsonEncode(result)}');

        if (result['success'] == true && result['exists'] == true) {
          // Check if verification data exists
          if (result['verification'] != null) {
            debugPrint(
                'Raw verification data: ${jsonEncode(result['verification'])}');
            final verificationData =
                VerificationModel.fromJson(result['verification']);

            // Check for selfieImageUrl directly in verification data
            String? selfieImageUrl = verificationData.selfieImageUrl;
            debugPrint(
                'Selfie image URL from verification model: $selfieImageUrl');

            // If not found in the verification model, check if it's in the faceImage field
            if ((selfieImageUrl == null || selfieImageUrl.isEmpty) &&
                result['faceImage'] != null &&
                result['faceImage']['face_image'] != null) {
              selfieImageUrl = result['faceImage']['face_image'];
              debugPrint(
                  'Selfie image URL from faceImage field: $selfieImageUrl');
            }

            setState(() {
              _verificationData = verificationData;
              _selfieImageUrl = selfieImageUrl;
              _verificationStatus = verificationData.status;
              _isVerified = verificationData.status == 'approved';
            });

            debugPrint('Final Selfie Image URL: $_selfieImageUrl');
            debugPrint('Verification Status: $_verificationStatus');
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

  Future<void> _captureSelfie() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        setState(() {
          _selfieImage = File(photo.path);
          _selfieImageName = photo.name;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selfie captured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing selfie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing selfie: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifySelfie() {
    if (_selfieImage != null) {
      widget.onSelfieVerified(_selfieImage!);
    } else if (_selfieImageUrl != null) {
      // If we have an existing image URL but no new image captured,
      // create a dummy file to continue the flow
      final dummyFile = File('dummy_path');
      widget.onSelfieVerified(dummyFile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _canProceed {
    return _selfieImage != null || _selfieImageUrl != null;
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
                            'Selfie Verification',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0272B1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please take a clear selfie to verify your identity',
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

                    // Verification Status Banner (if verified)
                    if (_verificationStatus != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _verificationStatus == 'approved'
                              ? Colors.green[50]
                              : _verificationStatus == 'rejected'
                                  ? Colors.red[50]
                                  : Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _verificationStatus == 'approved'
                                ? Colors.green[300]!
                                : _verificationStatus == 'rejected'
                                    ? Colors.red[300]!
                                    : Colors.amber[300]!,
                          ),
                        ),
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
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _verificationStatus == 'approved'
                                        ? 'Verification Approved'
                                        : _verificationStatus == 'rejected'
                                            ? 'Verification Rejected'
                                            : 'Verification Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _verificationStatus == 'approved'
                                          ? Colors.green[700]
                                          : _verificationStatus == 'rejected'
                                              ? Colors.red[700]
                                              : Colors.amber[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _verificationStatus == 'approved'
                                        ? 'Your selfie has been verified successfully.'
                                        : _verificationStatus == 'rejected'
                                            ? _verificationData
                                                    ?.rejectionReason ??
                                                'Your verification was rejected. Please submit a new selfie.'
                                            : 'Your verification is being reviewed.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_verificationStatus != null) const SizedBox(height: 24),

                    // Instructions (only show if not verified)
                    if (_verificationStatus != 'approved')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instructions:',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInstructionItem(
                                '1', 'Your face should be clearly visible'),
                            _buildInstructionItem(
                                '2', 'Take the photo in good lighting'),
                            _buildInstructionItem('3',
                                'Remove any accessories that cover your face (sunglasses, masks, etc.)'),
                          ],
                        ),
                      ),
                    if (_verificationStatus != 'approved')
                      const SizedBox(height: 32),

                    // Selfie Photo Container
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Take a Selfie',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _isVerified ? null : _captureSelfie,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selfieImage != null ||
                                          _selfieImageUrl != null
                                      ? Colors.green
                                      : const Color(0xFF0272B1)
                                          .withOpacity(0.5),
                                  width: _selfieImage != null ||
                                          _selfieImageUrl != null
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: _selfieImageUrl != null
                                  // Display the selfie image from URL for verified users
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(110),
                                      child: Image.network(
                                        _selfieImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            debugPrint(
                                                'Selfie image loaded successfully');
                                            return child;
                                          }
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                  color:
                                                      const Color(0xFF0272B1),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Loading image...',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          debugPrint(
                                              'Error loading selfie image: $error');
                                          debugPrint(
                                              'Selfie image URL: $_selfieImageUrl');
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 48,
                                                  color: Colors.red[400],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Failed to load image',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.red[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tap to retry',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : _selfieImage != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(110),
                                          child: Image.file(_selfieImage!,
                                              fit: BoxFit.cover),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Tap to take selfie',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                          if (_selfieImageName != null &&
                              _selfieImageUrl == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Selfie captured successfully',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (_selfieImageUrl != null && _selfieImage == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Existing selfie found',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Two buttons side by side: Capture and Next
                    Row(
                      children: [
                        // Capture Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isVerified ? null : _captureSelfie,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(
                                _selfieImage == null
                                    ? "Take Selfie"
                                    : "Retake Selfie",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Next Button - Only enabled when there's an image
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _canProceed ? _verifySelfie : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                "Next",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0272B1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.blue[100],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
