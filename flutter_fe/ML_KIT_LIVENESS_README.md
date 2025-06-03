# ML Kit Liveness Detection Implementation

This document explains the Google ML Kit face detection integration for liveness verification in the selfie verification process.

## Overview

The liveness detection system uses Google's ML Kit Face Detection API to verify that a real person (not a photo or video) is taking the selfie. Users are prompted to perform random actions like:

- **Smiling** - User must smile naturally
- **Blinking** - User must blink their eyes
- **Head Movement** - User must turn head left or right
- **Neutral Position** - Return to normal position between actions

## Features

### Enhanced Security
- **Anti-Spoofing**: Prevents verification using static photos
- **Real-time Detection**: Live face analysis during capture
- **Multiple Challenges**: Random sequence of 4 different actions
- **Neutral State Verification**: Ensures user returns to normal between actions

### User Experience
- **Visual Feedback**: Real-time face detection status
- **Progress Tracking**: Shows completion progress (1/4, 2/4, etc.)
- **Clear Instructions**: Step-by-step guidance for each action
- **Haptic Feedback**: Vibration on successful action completion
- **Dynamic UI**: Face detection oval changes color when face is detected

### Technical Implementation
- **Google ML Kit**: Uses `google_mlkit_face_detection` package
- **Camera Integration**: Real-time camera preview with overlay
- **Face Analysis**: Detects smiling probability, eye state, head rotation
- **Performance Optimized**: Uses `FaceDetectorMode.fast` for real-time processing

## How It Works

1. **Camera Initialization**: Front camera is initialized with high resolution
2. **Face Detection**: ML Kit continuously analyzes camera frames
3. **Challenge Sequence**: User must complete 4 random actions:
   - Actions are shuffled each session for security
   - User must return to neutral position between actions
   - Each action has specific detection thresholds
4. **Automatic Photo Capture**: After all challenges are completed, photo is captured automatically
5. **Verification**: Both liveness verification and captured selfie image are processed

## Detection Thresholds

### Smile Detection
- **Threshold**: `smilingProbability > 0.6` (60% confidence)
- **Reset**: `smilingProbability < 0.2` for neutral state

### Blink Detection
- **Threshold**: `eyeOpenProbability < 0.3` (eye closed)
- **Reset**: `eyeOpenProbability > 0.7` for neutral state

### Head Movement
- **Look Right**: `headEulerAngleY < -15°`
- **Look Left**: `headEulerAngleY > 15°`
- **Neutral**: `-10° < headEulerAngleY < 10°`

## Files Modified

### 1. `pubspec.yaml`
```yaml
dependencies:
  google_mlkit_face_detection: ^0.10.0
  camera: ^0.10.5
```

### 2. `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA" />

<queries>
  <intent>
    <action android:name="android.media.action.IMAGE_CAPTURE" />
  </intent>
</queries>
```

### 3. New Files Created
- `lib/view/verification/face_detection_page.dart` - Main liveness detection UI
- Enhanced `lib/view/verification/selfie_verification_page.dart` - Integration

## Error Handling

- **Camera Permission**: Graceful handling if permission denied
- **No Camera Available**: Fallback message and exit
- **Face Detection Errors**: Continuous retry without user interruption
- **Navigation Safety**: Proper cleanup on back button or close

## Security Considerations

- **Random Action Sequence**: Different order each time prevents replay attacks
- **Multiple Action Types**: Harder to fake with static images
- **Neutral State Verification**: Prevents holding expressions throughout
- **Real-time Processing**: Cannot use pre-recorded videos
- **Face Size Minimum**: `minFaceSize: 0.3` ensures proper detection distance

## Testing

To test the implementation:

1. **Grant Camera Permission**: Ensure camera access is allowed
2. **Good Lighting**: Test in well-lit environment for best detection
3. **Face Positioning**: Keep face centered in the oval
4. **Action Performance**: Perform actions clearly and naturally
5. **Complete Sequence**: Test all 4 random actions in sequence
6. **Automatic Capture**: Photo will be captured automatically after completing all challenges

## Reference

Based on the implementation guide from: [Flutter Liveness Detection with ML Kit](https://codewithwan.medium.com/flutter-liveness-detection-with-ml-kit-simplified-and-cool-9d2db2d46917)

## Notes

- Requires Android API 21+ and iOS 11.0+
- ML Kit models are downloaded on first use
- Performance may vary based on device capabilities
- Face detection works best with front-facing cameras 