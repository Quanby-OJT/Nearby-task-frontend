import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capture_identity/capture_identity.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
  String? _detectedIdType;
  List<String> _extractedText = [];
  bool _isLoading = false;
  bool _isProcessingImage = false;
  bool _isVerified = false;
  String? _idImageUrl;
  String? _verificationStatus;
  VerificationModel? _verificationData;

  // ML Kit Text Recognition
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

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

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
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

  // Enhanced ID capture with ML Kit text recognition
  Future<void> _captureIdImage() async {
    try {
      setState(() => _isLoading = true);

      // Use capture_identity package to capture ID document
      final File? capturedId = await showCapture(
        context: context,
        title: "Scan Your ID Document",
        hideIdWidget: false,
      );

      if (capturedId != null) {
        setState(() {
          _idImage = capturedId;
          _idImageName = capturedId.path.split('/').last;
          _isProcessingImage = true;
        });

        // Process image with ML Kit text recognition
        await _processImageWithMLKit(capturedId);

        // Show success message with detected information
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ID document captured successfully!'),
                  if (_detectedIdType != null)
                    Text('AI Detected: $_detectedIdType', 
                         style: const TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // User cancelled the capture
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID capture was cancelled'),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 2),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingImage = false;
        });
      }
    }
  }

  // Process captured image with ML Kit text recognition
  Future<void> _processImageWithMLKit(File imageFile) async {
    try {
      debugPrint('Processing image with ML Kit text recognition...');
      
      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);
      
      // Process image with text recognizer
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      List<String> extractedTextList = [];
      String fullText = recognizedText.text.toLowerCase();
      
      // Extract text from blocks
      for (TextBlock block in recognizedText.blocks) {
        extractedTextList.add(block.text);
        debugPrint('Detected text block: ${block.text}');
      }
      
      setState(() {
        _extractedText = extractedTextList;
      });
      
      // Detect ID type based on recognized text
      String? detectedType = _detectIdType(fullText);
      
      if (detectedType != null) {
        setState(() {
          _detectedIdType = detectedType;
          _selectedIdType = detectedType;
        });
        debugPrint('Detected ID type: $detectedType');
      } else {
        debugPrint('Could not determine ID type from text');
      }
      
      // Validate that this looks like an ID document
      bool isValidId = _validateIdDocument(fullText, extractedTextList);
      
      if (!isValidId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This doesn\'t appear to be a valid ID document. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      
    } catch (e) {
      debugPrint('Error processing image with ML Kit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing document: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Detect ID type based on recognized text
  String? _detectIdType(String text) {
    text = text.toLowerCase();
    
    // Driver's License detection
    if (text.contains('driver') || text.contains('license') || 
        text.contains('driving') || text.contains('dl no') ||
        text.contains('license no')) {
      return 'Driver\'s License';
    }
    
    // National ID detection
    if (text.contains('national') || text.contains('philsys') ||
        text.contains('national id') || text.contains('republic of the philippines')) {
      return 'National ID';
    }
    
    // Passport detection
    if (text.contains('passport') || text.contains('republic of the philippines') ||
        text.contains('pasaporte') || text.contains('type p')) {
      return 'Passport';
    }
    
    // SSS ID detection
    if (text.contains('sss') || text.contains('social security') ||
        text.contains('ss no') || text.contains('sss no')) {
      return 'SSS ID';
    }
    
    // PhilHealth ID detection
    if (text.contains('philhealth') || text.contains('phil health') ||
        text.contains('phic') || text.contains('pin')) {
      return 'PhilHealth ID';
    }
    
    // Voter's ID detection
    if (text.contains('voter') || text.contains('comelec') ||
        text.contains('precinct') || text.contains('voter\'s')) {
      return 'Voter\'s ID';
    }
    
    return null;
  }

  // Validate that the document contains ID-like information
  bool _validateIdDocument(String fullText, List<String> textBlocks) {
    // Check for common ID elements
    bool hasName = _containsName(fullText);
    bool hasNumbers = _containsIdNumbers(fullText);
    bool hasDate = _containsDate(fullText);
    
    // Should have at least 2 of these elements
    int validElements = [hasName, hasNumbers, hasDate].where((e) => e).length;
    
    debugPrint('ID Validation - Name: $hasName, Numbers: $hasNumbers, Date: $hasDate');
    
    return validElements >= 2 && textBlocks.length >= 3;
  }

  bool _containsName(String text) {
    // Look for common name patterns or prefixes
    return text.contains(RegExp(r'[a-z]+ [a-z]+')) || 
           text.contains('name') || text.contains('surname') ||
           text.contains('given') || text.contains('middle');
  }

  bool _containsIdNumbers(String text) {
    // Look for ID number patterns
    return text.contains(RegExp(r'\d{2,}')) || 
           text.contains('no') || text.contains('number') ||
           text.contains('#');
  }

  bool _containsDate(String text) {
    // Look for date patterns
    return text.contains(RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}')) ||
           text.contains(RegExp(r'\d{4}')) ||
           text.contains('birth') || text.contains('born') ||
           text.contains('exp') || text.contains('valid');
  }

  void _verifyId() {
    if (_formKey.currentState!.validate()) {
      if (_idImage != null) {
        // Use the captured image with detected or selected ID type
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
            content: Text('Please capture a photo of your ID document'),
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
                    // Enhanced Header
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: const Color(0xFFB71A4A),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Smart ID Verification',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB71A4A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI-powered document scanning with text recognition',
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

                    // ML Kit Detection Status Banner
                    if (_detectedIdType != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Detection: $_detectedIdType',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    'Document type automatically detected',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Enhanced Instructions (only show if not verified)
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
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFB71A4A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Smart Document Scanning',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71A4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '✨ AI-powered text recognition automatically detects your ID type\n'
                              '📄 Professional document capture with positioning guides\n'
                              '🔍 Text validation ensures document authenticity\n'
                              '⚡ Instant processing and smart error detection',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_verificationStatus != 'approved')
                      const SizedBox(height: 24),

                    // ID Photo Container with enhanced design
                    Text(
                      'ID Document Scan',
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _detectedIdType != null
                                ? Colors.green
                                : _idImage != null || _idImageUrl != null
                                    ? Colors.blue
                                    : const Color(0xFFB71A4A).withOpacity(0.5),
                            width: _idImage != null || _idImageUrl != null ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isProcessingImage
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: const Color(0xFFB71A4A),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Processing with AI...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'Analyzing document text',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              )
                            : _idImageUrl != null
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
                                        child: Image.file(_idImage!, fit: BoxFit.cover),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFB71A4A).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.document_scanner,
                                              size: 48,
                                              color: const Color(0xFFB71A4A),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tap to scan ID with AI',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Smart text recognition & validation',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                      ),
                    ),

                    // Status indicators
                    if (_detectedIdType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.psychology, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'AI detected: $_detectedIdType',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_idImageName != null && _idImageUrl == null && _detectedIdType == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Document captured successfully',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_idImageUrl != null && _idImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Existing ID document found',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Enhanced action buttons
                    Row(
                      children: [
                        // AI Scan Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isVerified ? null : _captureIdImage,
                              icon: const Icon(Icons.auto_awesome, color: Colors.white),
                              label: Text(
                                _idImage == null ? "AI Scan Document" : "Rescan with AI",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey[400],
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Verify Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: canProceed ? _verifyId : null,
                              icon: const Icon(Icons.verified, color: Colors.white),
                              label: Text(
                                "Verify",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71A4A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.blue[100],
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Debug extracted text (for development)
                    if (_extractedText.isNotEmpty && false) // Set to true for debugging
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Extracted Text:', 
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...(_extractedText.take(5).map((text) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(text, style: TextStyle(fontSize: 12)),
                                ))),
                          ],
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFB71A4A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessingImage
                        ? 'Processing with AI...'
                        : 'Loading verification status...',
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
    );
  }
}
