import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/model/verification_model.dart';
import 'existing_selfie_review_page.dart';
import 'selfie_review_page.dart';

class FaceDetectionPage extends StatefulWidget {
  final Function(File? capturedImage, bool success) onDetectionComplete;

  const FaceDetectionPage({super.key, required this.onDetectionComplete});

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  final GetStorage storage = GetStorage();

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFrontCamera = true;
  List<String> challengeActions = ['smile', 'blink', 'lookRight', 'lookLeft'];
  int currentActionIndex = 0;
  bool waitingForNeutral = false;
  int completedActions = 0;
  final int totalRequiredActions = 4;
  bool faceDetected = false;
  String statusMessage = '';
  bool isCapturingPhoto = false;
  bool isCheckingExistingImage = true;
  String? existingSelfieUrl;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;

  @override
  void initState() {
    super.initState();
    _checkForExistingSelfie();
  }

  // Check for existing selfie image first
  Future<void> _checkForExistingSelfie() async {
    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final result = await ApiService.getTaskerVerificationStatus(
            int.parse(userId.toString()));

        debugPrint('FaceDetection: Checking for existing selfie...');
        debugPrint('FaceDetection: API response: ${jsonEncode(result)}');

        if (result['success'] == true) {
          String? selfieImageUrl;

          // Check if verification data exists
          if (result['exists'] == true && result['verification'] != null) {
            final verificationData =
                VerificationModel.fromJson(result['verification']);
            selfieImageUrl = verificationData.selfieImageUrl;
            debugPrint(
                'FaceDetection: Selfie URL from verification: $selfieImageUrl');
          }

          // Check for images in additional data fields
          if ((selfieImageUrl == null || selfieImageUrl.isEmpty)) {
            if (result['faceImage'] != null &&
                result['faceImage']['face_image'] != null) {
              selfieImageUrl = result['faceImage']['face_image'];
              debugPrint(
                  'FaceDetection: ✅ Selfie URL from faceImage field: $selfieImageUrl');
            }
          }

          if (selfieImageUrl != null && selfieImageUrl.isNotEmpty) {
            // Show existing selfie in review screen
            setState(() {
              existingSelfieUrl = selfieImageUrl;
              isCheckingExistingImage = false;
            });
            _showExistingSelfieReview(selfieImageUrl);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('FaceDetection: Error checking existing selfie: $e');
    }

    // No existing selfie found, proceed with camera initialization
    setState(() {
      isCheckingExistingImage = false;
    });
    _initializeCameraAndStart();
  }

  // Initialize camera and start face detection
  void _initializeCameraAndStart() {
    initializeCamera();
    challengeActions.shuffle();
    statusMessage = 'Position your face in the oval';
  }

  // Show existing selfie in review screen
  void _showExistingSelfieReview(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExistingSelfieReviewPage(
          selfieImageUrl: imageUrl,
          onReviewComplete: (approved) {
            if (approved) {
              // User approved the existing selfie
              widget.onDetectionComplete(null, true);
            } else {
              // User wants to take a new selfie
              _initializeCameraAndStart();
            }
          },
        ),
      ),
    );
  }

  // Initialize the camera controller
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize();

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        startFaceDetection();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onDetectionComplete(null, false);
        Navigator.pop(context);
      }
    }
  }

  // Start face detection on the camera image stream
  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        if (!isDetecting && !isCapturingPhoto) {
          isDetecting = true;
          detectFaces(image).then((_) {
            isDetecting = false;
          });
        }
      });
    }
  }

  // Detect faces in the camera image
  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;
        setState(() {
          faceDetected = true;
          smilingProbability = face.smilingProbability;
          leftEyeOpenProbability = face.leftEyeOpenProbability;
          rightEyeOpenProbability = face.rightEyeOpenProbability;
          headEulerAngleY = face.headEulerAngleY;
        });
        checkChallenge(face);
      } else {
        if (faceDetected) {
          setState(() {
            faceDetected = false;
            statusMessage = 'Please position your face in the oval';
          });
        }
      }
    } catch (e) {
      debugPrint('Error in face detection: $e');
    }
  }

  // Check if the face is performing the current challenge action
  void checkChallenge(Face face) async {
    if (!faceDetected || isCapturingPhoto) return;

    if (waitingForNeutral) {
      if (isNeutralPosition(face)) {
        setState(() {
          waitingForNeutral = false;
          statusMessage =
              'Please ${getActionDescription(challengeActions[currentActionIndex])}';
        });
      } else {
        setState(() {
          statusMessage = 'Return to normal position first';
        });
        return;
      }
    }

    String currentAction = challengeActions[currentActionIndex];
    bool actionCompleted = false;

    switch (currentAction) {
      case 'smile':
        actionCompleted =
            face.smilingProbability != null && face.smilingProbability! > 0.6;
        break;
      case 'blink':
        actionCompleted = (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case 'lookRight':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! < -15;
        break;
      case 'lookLeft':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! > 15;
        break;
    }

    if (actionCompleted) {
      // Add a small delay and visual feedback for successful action
      HapticFeedback.lightImpact();

      setState(() {
        completedActions++;
        currentActionIndex++;
        statusMessage = 'Great! Action completed successfully';
      });

      // Wait a moment before continuing
      await Future.delayed(const Duration(milliseconds: 800));

      if (currentActionIndex >= challengeActions.length) {
        // All challenges completed successfully - capture photo automatically
        await _captureVerificationPhoto();
      } else {
        setState(() {
          waitingForNeutral = true;
          statusMessage = 'Return to normal position';
        });
      }
    } else {
      setState(() {
        statusMessage = 'Please ${getActionDescription(currentAction)}';
      });
    }
  }

  // Capture photo automatically after verification is complete
  Future<void> _captureVerificationPhoto() async {
    try {
      setState(() {
        isCapturingPhoto = true;
        statusMessage = 'Capturing your photo...';
      });

      // Stop the image stream before taking photo
      await cameraController.stopImageStream();

      // Wait a moment for the camera to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Take the photo
      final XFile photo = await cameraController.takePicture();

      setState(() {
        statusMessage = 'Photo captured successfully!';
      });

      // Wait a moment to show success message
      await Future.delayed(const Duration(milliseconds: 1000));

      // Navigate to selfie review page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelfieReviewPage(
              selfieImage: File(photo.path),
              onReviewComplete: (approved, newImage) {
                if (approved && newImage != null) {
                  // User approved the selfie
                  widget.onDetectionComplete(newImage, true);
                } else {
                  // User wants to retake - restart the face detection
                  setState(() {
                    isCapturingPhoto = false;
                    completedActions = 0;
                    currentActionIndex = 0;
                    waitingForNeutral = false;
                    statusMessage = 'Position your face in the oval';
                  });
                  challengeActions.shuffle();
                  startFaceDetection();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      setState(() {
        statusMessage = 'Error capturing photo. Please try again.';
        isCapturingPhoto = false;
      });

      // Restart face detection if photo capture failed
      startFaceDetection();
    }
  }

  // Check if the face is in a neutral position
  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.2) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  @override
  void dispose() {
    if (isCameraInitialized) {
      cameraController.stopImageStream().catchError((e) {
        debugPrint('Error stopping image stream: $e');
      });
      cameraController.dispose();
    }
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71A4A),
        title: Text(
          "Liveness Verification",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            widget.onDetectionComplete(null, false);
            Navigator.pop(context);
          },
        ),
      ),
      body: isCheckingExistingImage
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: const Color(0xFFB71A4A),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Checking for existing selfie...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : isCameraInitialized
              ? Stack(
                  children: [
                    // Camera preview
                    Positioned.fill(
                      child: CameraPreview(cameraController),
                    ),

                    // Face detection overlay
                    CustomPaint(
                      painter: HeadMaskPainter(faceDetected: faceDetected),
                      child: Container(),
                    ),

                    // Progress and instruction overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Progress bar
                            Row(
                              children: [
                                Text(
                                  'Progress: ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: isCapturingPhoto
                                        ? 1.0
                                        : completedActions /
                                            totalRequiredActions,
                                    backgroundColor: Colors.grey[400],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCapturingPhoto
                                          ? Colors.green
                                          : const Color(0xFFB71A4A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCapturingPhoto
                                      ? 'Complete!'
                                      : '$completedActions/$totalRequiredActions',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Face detection status
                            if (!isCapturingPhoto)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: faceDetected
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      faceDetected
                                          ? Icons.face
                                          : Icons.face_unlock_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      faceDetected
                                          ? 'Face Detected'
                                          : 'No Face Detected',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (!isCapturingPhoto) const SizedBox(height: 16),

                            // Current instruction
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isCapturingPhoto
                                    ? Colors.green
                                    : const Color(0xFFB71A4A),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCapturingPhoto) ...[
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      statusMessage,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Debug information (bottom left) - only show in debug mode
                    if (MediaQuery.of(context).size.height > 600 &&
                        faceDetected &&
                        !isCapturingPhoto)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detection Status:',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(1) : 'N/A'}%',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Eyes: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(1) : 'N/A'}%',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Head Y: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(1) : 'N/A'}°',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFB71A4A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing camera...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please allow camera access when prompted',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Get the description of the current challenge action
  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile naturally';
      case 'blink':
        return 'blink your eyes';
      case 'lookRight':
        return 'turn your head right';
      case 'lookLeft':
        return 'turn your head left';
      default:
        return 'follow the instruction';
    }
  }
}

// Custom painter for head mask overlay
class HeadMaskPainter extends CustomPainter {
  final bool faceDetected;

  HeadMaskPainter({this.faceDetected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2 - 50);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.25;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw oval border with dynamic color based on face detection
    final borderPaint = Paint()
      ..color = faceDetected ? Colors.green : const Color(0xFFB71A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      borderPaint,
    );

    // Add animated pulse effect when face is detected
    if (faceDetected) {
      final pulsePaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: (radiusX * 2) + 10,
          height: (radiusY * 2) + 10,
        ),
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint to show dynamic changes
  }
}
