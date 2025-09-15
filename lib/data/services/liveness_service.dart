import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'ml_kit_helper.dart';

enum LivenessChallenge {
  blink,
  turnLeft,
  turnRight,
  smile,
  nod,
}

enum LivenessState {
  idle,
  detecting,
  challengeActive,
  challengeCompleted,
  allCompleted,
  failed,
}

class LivenessResult {
  final bool success;
  final String message;
  final double confidence;
  final List<LivenessChallenge> completedChallenges;

  LivenessResult({
    required this.success,
    required this.message,
    required this.confidence,
    required this.completedChallenges,
  });
}

class LivenessService extends GetxService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,  // Needed for smile detection
      enableLandmarks: false,      // Disable landmarks to avoid warnings and improve performance
      enableContours: false,       // Not needed for liveness challenges
      enableTracking: true,        // Needed for face tracking
      performanceMode: FaceDetectorMode.accurate, // Use accurate mode for better liveness detection
      minFaceSize: 0.1,           // Minimum face size (10% of image)
    ),
  );

  final RxList<LivenessChallenge> challenges = <LivenessChallenge>[
    LivenessChallenge.blink,
    LivenessChallenge.turnLeft,
    LivenessChallenge.turnRight,
    LivenessChallenge.smile,
  ].obs;

  final Rx<LivenessState> state = LivenessState.idle.obs;
  final RxInt currentChallengeIndex = 0.obs;
  final RxList<bool> challengeResults = <bool>[].obs;
  final RxString currentInstruction = ''.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool isProcessing = false.obs;

  // Face tracking variables
  int? _primaryFaceId;
  bool _wasEyesClosed = false;
  bool _wasNotSmiling = false;
  double _baseHeadAngleY = 0.0;
  double _baseHeadAngleX = 0.0;
  bool _hasBaseAngles = false;
  
  // Challenge thresholds
  static const double _eyeClosedThreshold = 0.3;
  static const double _eyeOpenThreshold = 0.7;
  static const double _smileThreshold = 0.7;
  static const double _noSmileThreshold = 0.3;
  static const double _headTurnThreshold = 20.0;
  static const double _headNodThreshold = 15.0;

  // Anti-spoofing measures
  final RxInt consecutiveFramesWithFace = 0.obs;
  final RxBool hasStableFace = false.obs;
  static const int _minStableFrames = 10;
  
  // Throttling for face detection
  DateTime? _lastProcessTime;

  @override
  void onInit() {
    super.onInit();
    _updateInstruction();
  }

  @override
  void onClose() {
    _faceDetector.close();
    super.onClose();
  }

  void startLivenessDetection() {
    state.value = LivenessState.detecting;
    currentChallengeIndex.value = 0;
    challengeResults.clear();
    progress.value = 0.0;
    
    // Reset tracking variables
    _primaryFaceId = null;
    _wasEyesClosed = false;
    _wasNotSmiling = false;
    _hasBaseAngles = false;
    consecutiveFramesWithFace.value = 0;
    hasStableFace.value = false;
    
    _updateInstruction();
  }

  Future<void> processFrame(CameraImage image, CameraDescription camera) async {
    if (isProcessing.value || state.value == LivenessState.allCompleted) return;
    
    // Throttle processing to prevent buffer overflow (process max 3 frames per second)
    if (_lastProcessTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(_lastProcessTime!);
      if (timeSinceLastProcess.inMilliseconds < 333) {
        return;
      }
    }
    
    isProcessing.value = true;
    _lastProcessTime = DateTime.now();
    
    try {
      final inputImage = MLKitHelper.inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        consecutiveFramesWithFace.value = 0;
        hasStableFace.value = false;
        _updateInstruction();
        return;
      }

      // Use primary face or establish one
      Face? primaryFace = _getPrimaryFace(faces);
      if (primaryFace == null) return;

      consecutiveFramesWithFace.value++;
      
      // Wait for stable face detection
      if (consecutiveFramesWithFace.value >= _minStableFrames) {
        hasStableFace.value = true;
        
        // Set base angles for relative movement detection
        if (!_hasBaseAngles) {
          _baseHeadAngleY = primaryFace.headEulerAngleY ?? 0.0;
          _baseHeadAngleX = primaryFace.headEulerAngleX ?? 0.0;
          _hasBaseAngles = true;
        }
        
        if (state.value == LivenessState.detecting) {
          state.value = LivenessState.challengeActive;
        }
        
        if (state.value == LivenessState.challengeActive) {
          _checkCurrentChallenge(primaryFace);
        }
      }
      
      _updateInstruction();
      
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Face? _getPrimaryFace(List<Face> faces) {
    if (_primaryFaceId == null) {
      // Choose the largest face as primary
      Face largest = faces.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > 
        (b.boundingBox.width * b.boundingBox.height) ? a : b);
      _primaryFaceId = largest.trackingId;
      return largest;
    } else {
      // Find the tracked face
      try {
        return faces.firstWhere((face) => face.trackingId == _primaryFaceId);
      } catch (e) {
        // Face lost, reset
        _primaryFaceId = null;
        consecutiveFramesWithFace.value = 0;
        hasStableFace.value = false;
        return null;
      }
    }
  }

  void _checkCurrentChallenge(Face face) {
    if (currentChallengeIndex.value >= challenges.length) return;

    final challenge = challenges[currentChallengeIndex.value];
    bool challengeSuccess = false;

    switch (challenge) {
      case LivenessChallenge.blink:
        challengeSuccess = _checkBlinkChallenge(face);
        break;
      case LivenessChallenge.turnLeft:
        challengeSuccess = _checkHeadTurnLeftChallenge(face);
        break;
      case LivenessChallenge.turnRight:
        challengeSuccess = _checkHeadTurnRightChallenge(face);
        break;
      case LivenessChallenge.smile:
        challengeSuccess = _checkSmileChallenge(face);
        break;
      case LivenessChallenge.nod:
        challengeSuccess = _checkNodChallenge(face);
        break;
    }

    if (challengeSuccess) {
      _completeCurrentChallenge();
    }
  }

  bool _checkBlinkChallenge(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    // Eyes are closed
    if (leftEyeOpen < _eyeClosedThreshold && rightEyeOpen < _eyeClosedThreshold) {
      _wasEyesClosed = true;
      return false;
    }

    // Eyes are open after being closed (blink detected)
    if (_wasEyesClosed && leftEyeOpen > _eyeOpenThreshold && rightEyeOpen > _eyeOpenThreshold) {
      return true;
    }

    return false;
  }

  bool _checkHeadTurnLeftChallenge(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final relativeTurn = headEulerAngleY - _baseHeadAngleY;
    
    return relativeTurn > _headTurnThreshold;
  }

  bool _checkHeadTurnRightChallenge(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final relativeTurn = headEulerAngleY - _baseHeadAngleY;
    
    return relativeTurn < -_headTurnThreshold;
  }

  bool _checkSmileChallenge(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;

    // Not smiling initially
    if (smilingProbability < _noSmileThreshold) {
      _wasNotSmiling = true;
      return false;
    }

    // Now smiling after not smiling
    if (_wasNotSmiling && smilingProbability > _smileThreshold) {
      return true;
    }

    return false;
  }

  bool _checkNodChallenge(Face face) {
    final headEulerAngleX = face.headEulerAngleX ?? 0.0;
    final relativeNod = headEulerAngleX - _baseHeadAngleX;
    
    // Check for downward nod
    return relativeNod.abs() > _headNodThreshold;
  }

  void _completeCurrentChallenge() {
    challengeResults.add(true);
    state.value = LivenessState.challengeCompleted;
    
    // Reset challenge-specific tracking
    _wasEyesClosed = false;
    _wasNotSmiling = false;
    
    // Move to next challenge or complete
    Future.delayed(const Duration(milliseconds: 1500), () {
      currentChallengeIndex.value++;
      progress.value = currentChallengeIndex.value / challenges.length;
      
      if (currentChallengeIndex.value >= challenges.length) {
        state.value = LivenessState.allCompleted;
      } else {
        state.value = LivenessState.challengeActive;
        // Reset base angles for next challenge
        _hasBaseAngles = false;
      }
      
      _updateInstruction();
    });
  }

  void _updateInstruction() {
    if (!hasStableFace.value) {
      currentInstruction.value = 'Position your face in the center';
      return;
    }

    switch (state.value) {
      case LivenessState.idle:
        currentInstruction.value = 'Preparing liveness check...';
        break;
      case LivenessState.detecting:
        currentInstruction.value = 'Hold still, detecting face...';
        break;
      case LivenessState.challengeActive:
        if (currentChallengeIndex.value < challenges.length) {
          currentInstruction.value = _getChallengeInstruction(challenges[currentChallengeIndex.value]);
        }
        break;
      case LivenessState.challengeCompleted:
        currentInstruction.value = 'Great! Moving to next challenge...';
        break;
      case LivenessState.allCompleted:
        currentInstruction.value = 'Liveness check completed successfully!';
        break;
      case LivenessState.failed:
        currentInstruction.value = 'Liveness check failed. Please try again.';
        break;
    }
  }

  String _getChallengeInstruction(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.blink:
        return 'Please blink your eyes';
      case LivenessChallenge.turnLeft:
        return 'Turn your head to the left';
      case LivenessChallenge.turnRight:
        return 'Turn your head to the right';
      case LivenessChallenge.smile:
        return 'Please smile';
      case LivenessChallenge.nod:
        return 'Nod your head up and down';
    }
  }

  LivenessResult getLivenessResult() {
    final completedCount = challengeResults.where((result) => result).length;
    final totalChallenges = challenges.length;
    final confidence = completedCount / totalChallenges;
    
    final success = state.value == LivenessState.allCompleted && 
                   completedCount == totalChallenges;
    
    return LivenessResult(
      success: success,
      message: success ? 'Liveness verification successful' : 'Liveness verification failed',
      confidence: confidence,
      completedChallenges: challenges.take(completedCount).toList(),
    );
  }

  void resetLivenessDetection() {
    debugPrint('[LivenessService] Resetting liveness detection state...');

    state.value = LivenessState.idle;
    currentChallengeIndex.value = 0;
    challengeResults.clear();
    progress.value = 0.0;
    currentInstruction.value = '';
    isProcessing.value = false;

    // Reset face tracking variables
    _primaryFaceId = null;
    _wasEyesClosed = false;
    _wasNotSmiling = false;
    _hasBaseAngles = false;
    _baseHeadAngleY = 0.0;
    _baseHeadAngleX = 0.0;
    consecutiveFramesWithFace.value = 0;
    hasStableFace.value = false;

    // Clear throttling timestamp to allow immediate processing
    _lastProcessTime = null;

    debugPrint('[LivenessService] Reset complete');
  }


  // Getter for current challenge
  LivenessChallenge? get currentChallenge {
    if (currentChallengeIndex.value < challenges.length) {
      return challenges[currentChallengeIndex.value];
    }
    return null;
  }

  // Check if liveness detection is active
  bool get isActive => state.value != LivenessState.idle && state.value != LivenessState.allCompleted;
}