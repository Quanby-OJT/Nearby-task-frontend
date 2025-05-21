import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/model/verification_model.dart';

class IdVerificationPage extends StatefulWidget {
  final Function(File idImage, String idType) onIdVerified;

  const IdVerificationPage({super.key, required this.onIdVerified});

  @override
  State<IdVerificationPage> createState() => _IdVerificationPageState();
}

class _IdVerificationPageState extends State<IdVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final storage = GetStorage();

  File? _idImage;
  String? _idImageName;
  String? _selectedIdType;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _idImageUrl;
  String? _verificationStatus;
  VerificationModel? _verificationData;

  final List<String> _idTypes = [
    'Driver\'s License',
    'National ID',
    'Passport',
    'SSS ID',
    'PhilHealth ID',
    'Voter\'s ID',
    'Other Government ID'
  ];

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

            // Check for idImageUrl directly in verification data
            String? idImageUrl = verificationData.idImageUrl;
            debugPrint('ID image URL from verification model: $idImageUrl');

            // If not found in the verification model, check if it's in the idImage field
            if ((idImageUrl == null || idImageUrl.isEmpty) &&
                result['idImage'] != null &&
                result['idImage']['id_image'] != null) {
              idImageUrl = result['idImage']['id_image'];
              debugPrint('ID image URL from idImage field: $idImageUrl');
            }

            setState(() {
              _verificationData = verificationData;
              _idImageUrl = idImageUrl;
              _selectedIdType = verificationData.idType;
              _verificationStatus = verificationData.status;
              _isVerified = verificationData.status == 'approved';
            });

            debugPrint('Final ID Image URL: $_idImageUrl');
            debugPrint('ID Type: $_selectedIdType');
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

  Future<void> _captureIdImage() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _idImage = File(photo.path);
          _idImageName = photo.name;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID photo captured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing ID image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing ID: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyId() {
    if (_formKey.currentState!.validate()) {
      if (_idImage != null) {
        // Use the captured image with empty string for ID type
        widget.onIdVerified(_idImage!, _selectedIdType ?? '');
      } else if (_idImageUrl != null) {
        // If we have an existing image URL but no new image captured,
        // create a dummy file to continue the flow
        final dummyFile = File('dummy_path');
        widget.onIdVerified(dummyFile, _selectedIdType ?? '');
      } else {
        // No image at all
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture a photo of your ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _canProceed {
    // Only check if we have an image, ID type is no longer required
    final hasImage = _idImage != null || _idImageUrl != null;
    final canProceed = hasImage;

    debugPrint('Can proceed check:');
    debugPrint(
        '  - Has Image: $hasImage (new: ${_idImage != null}, existing: ${_idImageUrl != null})');
    debugPrint('  - Can Proceed: $canProceed');

    return canProceed;
  }

  bool get _hasImage {
    return _idImage != null || _idImageUrl != null;
  }

  @override
  Widget build(BuildContext context) {
    // Check if we can proceed whenever the widget builds
    final canProceed = _canProceed;

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
                            'ID Verification',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB71A4A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please upload a valid government-issued ID',
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
                                        ? 'Your ID has been verified successfully.'
                                        : _verificationStatus == 'rejected'
                                            ? _verificationData
                                                    ?.rejectionReason ??
                                                'Your verification was rejected. Please submit a new ID.'
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
                          color: Color(0xFFB71A4A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color(0xFFB71A4A).withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instructions:',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB71A4A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInstructionItem(
                                '1', 'Take a clear, well-lit photo of your ID'),
                            _buildInstructionItem('2',
                                'Make sure all information is clearly visible'),
                            _buildInstructionItem('3',
                                'All four corners of the ID must be in the frame'),
                          ],
                        ),
                      ),
                    if (_verificationStatus != 'approved')
                      const SizedBox(height: 24),

                    // ID Photo Container
                    Text(
                      'ID Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isVerified ? null : _captureIdImage,
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _idImage != null || _idImageUrl != null
                                ? Colors.green
                                : const Color(0xFFB71A4A).withOpacity(0.5),
                            width:
                                _idImage != null || _idImageUrl != null ? 2 : 1,
                          ),
                        ),
                        child: _idImageUrl != null
                            // Display the ID image from URL for verified users
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  _idImageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      debugPrint(
                                          'ID image loaded successfully');
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
                                            color: const Color(0xFFB71A4A),
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
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                        'Error loading ID image: $error');
                                    debugPrint('ID image URL: $_idImageUrl');
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
                            : _idImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(_idImage!,
                                        fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tap to capture ID photo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Use your camera to take a photo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    if (_idImageName != null && _idImageUrl == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Photo captured successfully',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (_idImageUrl != null && _idImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Existing ID photo found',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Two buttons side by side: Capture and Next
                    Row(
                      children: [
                        // Capture Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isVerified ? null : _captureIdImage,
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              label: Text(
                                _idImage == null
                                    ? "Capture ID"
                                    : "Retake Photo",
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
                        // Next Button - Only enabled when there's an image AND ID type selected
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: canProceed ? _verifyId : null,
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                              label: Text(
                                "Next",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71A4A),
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

                    // Debug information (only in debug mode)
                    if (false) // Set to true during debugging
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Debug Info:'),
                              Text('ID Type: $_selectedIdType'),
                              Text('Has Image: $_hasImage'),
                              Text('Can Proceed: $canProceed'),
                            ],
                          ),
                        ),
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
                color: Color(0xFFB71A4A),
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
              color: Color(0xFFB71A4A),
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

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB71A4A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[600]!, width: 2),
      ),
    );
  }
}
