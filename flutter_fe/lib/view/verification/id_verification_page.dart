import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
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

class _IdVerificationPageState extends State<IdVerificationPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final storage = GetStorage();

  // Camera and capture
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;

  // Image quality detection
  bool _isImageClear = false;
  bool _isIdDetected = false;

  // ID verification data
  File? _idImage;
  String? _selectedIdType;
  String? _detectedIdType;
  List<String> _extractedText = [];
  bool _isLoading = false;
  bool _isVerified = false;
  String? _idImageUrl;
  String? _verificationStatus;
  VerificationModel? _verificationData;

  // ML Kit Text Recognition
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // Auto-capture settings
  bool _autoCapturingEnabled = false;
  int _qualityCheckCounter = 0;
  final int _requiredQualityChecks = 3; // Consecutive quality checks needed

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
    WidgetsBinding.instance.addObserver(this);
    _isLoading = true;
    _checkVerificationStatus().then((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          
          // Start continuous quality monitoring
          _startQualityMonitoring();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final result = await ApiService.getTaskerVerificationStatus(
            int.parse(userId.toString()));

        if (result['success'] == true && result['exists'] == true) {
          if (result['verification'] != null) {
            final verificationData =
                VerificationModel.fromJson(result['verification']);

            String? idImageUrl = verificationData.idImageUrl;
            if ((idImageUrl == null || idImageUrl.isEmpty) &&
                result['idImage'] != null &&
                result['idImage']['id_image'] != null) {
              idImageUrl = result['idImage']['id_image'];
            }

            setState(() {
              _verificationData = verificationData;
              _idImageUrl = idImageUrl;
              _selectedIdType = verificationData.idType;
              _verificationStatus = verificationData.status;
              _isVerified = verificationData.status == 'approved';
            });
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

  void _startQualityMonitoring() {
    if (!_isCameraInitialized) return;
    
    // Monitor image quality every 500ms
    Stream.periodic(const Duration(milliseconds: 500)).listen((_) async {
      if (_cameraController != null && 
          _cameraController!.value.isInitialized && 
          !_isCapturing && 
          !_isProcessing) {
        await _checkImageQuality();
      }
    });
  }

  Future<void> _checkImageQuality() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      // Take a temporary image for quality analysis
      final XFile tempImage = await _cameraController!.takePicture();
      final File tempFile = File(tempImage.path);
      
      // Process with ML Kit for text detection
      final inputImage = InputImage.fromFile(tempFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Check if ID-related text is detected
      bool hasIdText = _containsIdText(recognizedText.text);
      
      setState(() {
        _isImageClear = hasIdText;
        _isIdDetected = hasIdText;
      });

      // Auto-capture logic
      if (_autoCapturingEnabled && _isImageClear && _isIdDetected) {
        _qualityCheckCounter++;
        if (_qualityCheckCounter >= _requiredQualityChecks) {
          await _captureIdAutomatically(tempFile);
        }
      } else {
        _qualityCheckCounter = 0;
      }

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('Failed to delete temp file: $e');
      }

    } catch (e) {
      debugPrint('Error checking image quality: $e');
    }
  }

  bool _containsIdText(String text) {
    final String lowercaseText = text.toLowerCase();
    
    // Common ID document keywords
    final List<String> idKeywords = [
      'republic', 'philippines', 'driver', 'license', 'national', 'id',
      'passport', 'identification', 'card', 'government', 'issued',
      'department', 'lto', 'dfa', 'psa', 'sss', 'philhealth',
      'voter', 'valid', 'until', 'expires', 'date', 'birth',
      'address', 'signature', 'thumb', 'mark'
    ];
    
    int keywordCount = 0;
    for (String keyword in idKeywords) {
      if (lowercaseText.contains(keyword)) {
        keywordCount++;
      }
    }
    
    // Consider it an ID if at least 2 keywords are found
    return keywordCount >= 2;
  }

  Future<void> _captureIdAutomatically(File imageFile) async {
    if (_isCapturing) return;
    
    try {
      setState(() {
        _isCapturing = true;
        _isProcessing = true;
      });

      // Provide haptic feedback
      HapticFeedback.heavyImpact();

      // Process the captured image
      await _processImageWithMLKit(imageFile);

      setState(() {
        _idImage = imageFile;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ ID automatically captured!'),
                if (_detectedIdType != null)
                  Text('🤖 AI Detected: $_detectedIdType',
                       style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset auto-capture
      _autoCapturingEnabled = false;
      _qualityCheckCounter = 0;

    } catch (e) {
      debugPrint('Error in auto-capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-capture failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _captureIdManually() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
        _isProcessing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      // Process the image
      await _processImageWithMLKit(imageFile);

      setState(() {
        _idImage = imageFile;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ ID captured successfully!'),
                if (_detectedIdType != null)
                  Text('🤖 AI Detected: $_detectedIdType',
                       style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      debugPrint('Error capturing ID manually: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImageWithMLKit(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      List<String> textLines = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          textLines.add(line.text);
        }
      }

      setState(() {
        _extractedText = textLines;
        _detectedIdType = _detectIdType(recognizedText.text);
        if (_detectedIdType != null && _selectedIdType == null) {
          _selectedIdType = _detectedIdType;
        }
      });

    } catch (e) {
      debugPrint('Error processing image with ML Kit: $e');
    }
  }

  String? _detectIdType(String text) {
    final String lowercaseText = text.toLowerCase();

    if (lowercaseText.contains('driver') && lowercaseText.contains('license')) {
      return 'Driver\'s License';
    } else if (lowercaseText.contains('national') && lowercaseText.contains('id')) {
      return 'National ID';
    } else if (lowercaseText.contains('passport')) {
      return 'Passport';
    } else if (lowercaseText.contains('sss')) {
      return 'SSS ID';
    } else if (lowercaseText.contains('philhealth')) {
      return 'PhilHealth ID';
    } else if (lowercaseText.contains('voter')) {
      return 'Voter\'s ID';
    } else if (lowercaseText.contains('government') || 
               lowercaseText.contains('republic') ||
               lowercaseText.contains('philippines')) {
      return 'Other Government ID';
    }
    return null;
  }

  void _submitId() {
    if (_formKey.currentState!.validate() && _idImage != null) {
      widget.onIdVerified(_idImage!, _selectedIdType!);
    }
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        
        // Custom overlay for ID guidance
        Positioned.fill(
          child: CustomPaint(
            painter: IdOverlayPainter(
              isImageClear: _isImageClear,
              isIdDetected: _isIdDetected,
            ),
          ),
        ),
        
        // Quality indicators
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isImageClear ? Icons.check_circle : Icons.warning,
                      color: _isImageClear ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isImageClear ? 'Image Clear' : 'Image Blurry',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _isIdDetected ? Icons.credit_card : Icons.search,
                      color: _isIdDetected ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isIdDetected ? 'ID Detected' : 'Position ID in frame',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                if (_autoCapturingEnabled && _qualityCheckCounter > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: _qualityCheckCounter / _requiredQualityChecks,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              // Auto-capture toggle
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Auto Capture',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _autoCapturingEnabled,
                            onChanged: (value) {
                              setState(() {
                                _autoCapturingEnabled = value;
                                _qualityCheckCounter = 0;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Manual capture button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: IconButton(
                      onPressed: _isCapturing ? null : _captureIdManually,
                      icon: Icon(
                        Icons.camera,
                        size: 32,
                        color: _isCapturing ? Colors.grey : Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Processing overlay
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing ID...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
        backgroundColor: const Color(0xFFB71A4A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Smart ID Capture',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Position your ID within the frame\n'
                      '• Ensure good lighting and clear text\n'
                      '• Enable auto-capture for hands-free operation\n'
                      '• System will automatically detect blur and quality',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Camera view or captured image
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                clipBehavior: Clip.hardEdge,
                child: _idImage != null
                    ? Image.file(_idImage!, fit: BoxFit.cover)
                    : _buildCameraView(),
              ),
              
              const SizedBox(height: 20),
              
              // ID Type Selection
              Text(
                'ID Type',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIdType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Select ID type',
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: Colors.grey[600],
                  ),
                ),
                items: _idTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIdType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an ID type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Extracted text preview (if available)
              if (_extractedText.isNotEmpty) ...[
                Text(
                  'Extracted Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_detectedIdType != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '🤖 AI Detected: $_detectedIdType',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      Text(
                        _extractedText.join('\n'),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Retake button
              if (_idImage != null)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _idImage = null;
                        _extractedText.clear();
                        _detectedIdType = null;
                      });
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake Photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB71A4A),
                    ),
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_idImage != null && _selectedIdType != null)
                      ? _submitId
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71A4A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue to Selfie Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for ID overlay guidance
class IdOverlayPainter extends CustomPainter {
  final bool isImageClear;
  final bool isIdDetected;

  IdOverlayPainter({
    required this.isImageClear,
    required this.isIdDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Define the ID card frame (centered, landscape orientation)
    final double frameWidth = size.width * 0.8;
    final double frameHeight = frameWidth * 0.63; // Standard ID card ratio
    final Rect frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    // Frame color based on detection status
    Color frameColor;
    if (isImageClear && isIdDetected) {
      frameColor = Colors.green;
    } else if (isImageClear || isIdDetected) {
      frameColor = Colors.orange;
    } else {
      frameColor = Colors.red;
    }

    paint.color = frameColor;

    // Draw rounded rectangle frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      paint,
    );

    // Draw corner guides
    final double cornerLength = 20;
    final Paint cornerPaint = Paint()
      ..color = frameColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(frame.left, frame.top + cornerLength),
      Offset(frame.left, frame.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frame.left, frame.top),
      Offset(frame.left + cornerLength, frame.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(frame.right - cornerLength, frame.top),
      Offset(frame.right, frame.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frame.right, frame.top),
      Offset(frame.right, frame.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(frame.left, frame.bottom - cornerLength),
      Offset(frame.left, frame.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frame.left, frame.bottom),
      Offset(frame.left + cornerLength, frame.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frame.right - cornerLength, frame.bottom),
      Offset(frame.right, frame.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frame.right, frame.bottom),
      Offset(frame.right, frame.bottom - cornerLength),
      cornerPaint,
    );

    // Darken areas outside the frame
    final Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)));
    
    final Path overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant IdOverlayPainter oldDelegate) {
    return isImageClear != oldDelegate.isImageClear ||
           isIdDetected != oldDelegate.isIdDetected;
  }
}
