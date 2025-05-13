import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SelfieVerificationPage extends StatefulWidget {
  final Function(File selfieImage) onSelfieVerified;

  const SelfieVerificationPage({super.key, required this.onSelfieVerified});

  @override
  State<SelfieVerificationPage> createState() => _SelfieVerificationPageState();
}

class _SelfieVerificationPageState extends State<SelfieVerificationPage> {
  final _formKey = GlobalKey<FormState>();

  File? _selfieImage;
  String? _selfieImageName;
  bool _isLoading = false;

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a selfie photo'),
          backgroundColor: Colors.red,
        ),
      );
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

                    // Instructions
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
                            onTap: _captureSelfie,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selfieImage != null
                                      ? Colors.green
                                      : const Color(0xFF0272B1)
                                          .withOpacity(0.5),
                                  width: _selfieImage != null ? 2 : 1,
                                ),
                              ),
                              child: _selfieImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(110),
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
                          if (_selfieImageName != null)
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _selfieImage == null
                            ? _captureSelfie
                            : _verifySelfie,
                        icon: Icon(_selfieImage == null
                            ? Icons.camera_alt
                            : Icons.check_circle),
                        label: Text(
                          _selfieImage == null
                              ? "Take Selfie"
                              : "Continue to Documents",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_selfieImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _captureSelfie,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              'Retake Selfie',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
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
