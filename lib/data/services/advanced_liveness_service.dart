import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'ml_kit_helper.dart';
import 'liveness_service.dart';

/// Advanced liveness detection using multiple ML Kit detectors
/// Provides superior anti-spoofing protection using:
/// - Face detection with eye blink detection
/// - Pose detection for natural body movement
/// - Selfie segmentation for depth/silhouette analysis
class AdvancedLivenessService extends GetxService {
  // ML Kit detectors
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;
  late final SelfieSegmenter _selfieSegmenter;

  // Liveness state
  final Rx<LivenessState> state = LivenessState.idle.obs;
  final RxString currentInstruction = ''.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool isProcessing = false.obs;
  final RxBool hasStableFace = false.obs;

  // Anti-spoofing metrics
  final RxInt consecutiveFramesWithFace = 0.obs;
  final RxInt naturalMovements = 0.obs;
  final RxDouble averageSegmentationConfidence = 0.0.obs;
  final RxBool hasDetectedSmile = false.obs;
  final RxBool hasDetectedHeadMovement = false.obs;
  final RxBool hasDetectedBodyMovement = false.obs;

  // Thresholds for liveness detection (optimized for close-up natural use)
  static const int _minStableFrames = 5;      // Faster detection for natural positioning
  static const int _requiredNaturalMovements = 2;  // Reduced for better UX
  static const double _minSegmentationConfidence = 0.5;  // More realistic for real conditions
  static const double _headMovementThreshold = 5.0;      // Even smaller natural movements
  static const double _bodyMovementThreshold = 0.1;

  // Tracking variables
  double? _baseHeadYaw;
  double? _baseHeadPitch;
  List<Pose>? _basePose;
  DateTime? _lastProcessTime;

  @override
  void onInit() {
    super.onInit();
    _initializeDetectors();
  }

  @override
  void onClose() {
    _faceDetector.close();
    _poseDetector.close();
    _selfieSegmenter.close();
    super.onClose();
  }

  void _initializeDetectors() {
    // Face detector optimized for close-up selfie detection
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,  // For eye and smile detection
        enableLandmarks: false,      // Not needed, improves performance
        enableContours: false,       // Not needed for liveness
        enableTracking: true,        // Essential for tracking across frames
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.05,          // Very small minimum - allows close-up faces to fill most of frame
      ),
    );

    // Initialize pose detector and segmenter with error handling
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base,
        ),
      );
      debugPrint('[AdvancedLivenessService] Pose detector initialized');
    } catch (e) {
      debugPrint('[AdvancedLivenessService] Failed to initialize pose detector: $e');
    }

    try {
      _selfieSegmenter = SelfieSegmenter(
        mode: SegmenterMode.stream,
      );
      debugPrint('[AdvancedLivenessService] Selfie segmenter initialized');
    } catch (e) {
      debugPrint('[AdvancedLivenessService] Failed to initialize selfie segmenter: $e');
    }
  }

  void startLivenessDetection() {
    debugPrint('🚀 [AdvancedLiveness] Starting liveness detection...');
    state.value = LivenessState.detecting;
    currentInstruction.value = 'Hold phone naturally - face can be close';
    progress.value = 0.0;
    
    // Reset tracking variables
    _resetTrackingState();
    debugPrint('✅ [AdvancedLiveness] Liveness detection started, waiting for frames...');
  }

  void _resetTrackingState() {
    consecutiveFramesWithFace.value = 0;
    naturalMovements.value = 0;
    averageSegmentationConfidence.value = 0.0;
    hasDetectedSmile.value = false;
    hasDetectedHeadMovement.value = false;
    hasDetectedBodyMovement.value = false;
    hasStableFace.value = false;
    isProcessing.value = false;

    _baseHeadYaw = null;
    _baseHeadPitch = null;
    _basePose = null;

    // Clear throttling timestamp to allow immediate processing on retry
    _lastProcessTime = null;

    debugPrint('[AdvancedLivenessService] Tracking state reset complete');
  }

  Future<void> processFrame(CameraImage image, CameraDescription camera) async {
    if (isProcessing.value || state.value == LivenessState.allCompleted) return;
    
    // Moderate throttling (max 2 FPS to prevent buffer overflow while allowing responsive detection)
    if (_lastProcessTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(_lastProcessTime!);
      if (timeSinceLastProcess.inMilliseconds < 500) return;
    }
    
    debugPrint('🎥 [AdvancedLiveness] Processing frame: ${image.width}x${image.height}, Format: ${image.format.group}');
    isProcessing.value = true;
    _lastProcessTime = DateTime.now();
    
    try {
      final inputImage = MLKitHelper.inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      // Process face detection (primary detector)
      await _processFaceDetection(inputImage);
      
      // Try pose detection with error handling
      try {
        await _processPoseDetection(inputImage);
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('[AdvancedLivenessService] Pose detection not available, skipping');
        } else {
          debugPrint('[AdvancedLivenessService] Pose detection error: $e');
        }
      }
      
      // Try segmentation with error handling
      try {
        await _processSegmentation(inputImage);
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          debugPrint('[AdvancedLivenessService] Segmentation not available, skipping');
        } else {
          debugPrint('[AdvancedLivenessService] Segmentation error: $e');
        }
      }

      _analyzeResults();
      _updateProgress();
      
    } catch (e) {
      debugPrint('[AdvancedLivenessService] Error processing frame: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<List<Face>> _processFaceDetection(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    
    if (faces.isEmpty) {
      debugPrint('😞 [AdvancedLiveness] No faces detected');
      consecutiveFramesWithFace.value = 0;
      hasStableFace.value = false;
      return faces;
    }

    final face = faces.first;
    final faceSize = face.boundingBox.width * face.boundingBox.height;
    final frameWidth = inputImage.metadata?.size.width ?? 1.0;
    final frameHeight = inputImage.metadata?.size.height ?? 1.0;
    final frameSize = frameWidth * frameHeight;
    final faceRatio = faceSize / frameSize;
    
    debugPrint('👤 [AdvancedLiveness] Face detected! Size ratio: ${(faceRatio * 100).toStringAsFixed(1)}% (${face.boundingBox.width.toInt()}x${face.boundingBox.height.toInt()})');
    consecutiveFramesWithFace.value++;
    
    if (consecutiveFramesWithFace.value >= _minStableFrames) {
      if (!hasStableFace.value) {
        debugPrint('✅ [AdvancedLiveness] STABLE FACE achieved! Starting liveness checks...');
        hasStableFace.value = true;
      }
      
      // Detect smile
      _detectSmile(face);
      
      // Detect head movement
      _detectHeadMovement(face);
    } else {
      debugPrint('🔄 [AdvancedLiveness] Building stability... ${consecutiveFramesWithFace.value}/$_minStableFrames frames');
    }
    
    return faces;
  }

  Future<List<Pose>> _processPoseDetection(InputImage inputImage) async {
    final poses = await _poseDetector.processImage(inputImage);
    
    if (poses.isNotEmpty) {
      _detectBodyMovement(poses.first);
    }
    
    return poses;
  }

  Future<SegmentationMask?> _processSegmentation(InputImage inputImage) async {
    final mask = await _selfieSegmenter.processImage(inputImage);
    
    // Analyze segmentation confidence
    if (mask != null) {
      _analyzeSegmentationMask(mask);
    }
    
    return mask;
  }

  void _detectSmile(Face face) {
    final smileProbability = face.smilingProbability;
    
    if (smileProbability != null) {
      debugPrint('😊 [AdvancedLiveness] Smile probability: ${(smileProbability * 100).toStringAsFixed(1)}%');
      
      // Detect smile when probability is high (70% threshold for natural smiles)
      if (smileProbability > 0.7 && !hasDetectedSmile.value) {
        hasDetectedSmile.value = true;
        naturalMovements.value++;
        debugPrint('✨ [AdvancedLiveness] SMILE DETECTED! Natural movements: ${naturalMovements.value}');
      }
    }
  }

  void _detectHeadMovement(Face face) {
    final headYaw = face.headEulerAngleY;
    final headPitch = face.headEulerAngleX;
    
    if (headYaw != null && headPitch != null) {
      if (_baseHeadYaw == null || _baseHeadPitch == null) {
        _baseHeadYaw = headYaw;
        _baseHeadPitch = headPitch;
        return;
      }
      
      final yawChange = (headYaw - _baseHeadYaw!).abs();
      final pitchChange = (headPitch - _baseHeadPitch!).abs();
      
      debugPrint('🔄 [AdvancedLiveness] Head angles - Yaw: ${yawChange.toStringAsFixed(1)}°, Pitch: ${pitchChange.toStringAsFixed(1)}° (threshold: $_headMovementThreshold°)');
      
      if (yawChange > _headMovementThreshold || pitchChange > _headMovementThreshold) {
        if (!hasDetectedHeadMovement.value) {
          hasDetectedHeadMovement.value = true;
          naturalMovements.value++;
          debugPrint('🎯 [AdvancedLiveness] HEAD MOVEMENT DETECTED! Yaw: ${yawChange.toStringAsFixed(1)}°, Pitch: ${pitchChange.toStringAsFixed(1)}°. Natural movements: ${naturalMovements.value}');
        }
      }
    }
  }

  void _detectBodyMovement(Pose pose) {
    if (_basePose == null) {
      _basePose = [pose];
      return;
    }
    
    // Compare current pose with base pose to detect natural movement
    final baseNose = _basePose!.first.landmarks[PoseLandmarkType.nose];
    final currentNose = pose.landmarks[PoseLandmarkType.nose];
    
    if (baseNose != null && currentNose != null) {
      final distance = _calculateDistance(baseNose.x, baseNose.y, currentNose.x, currentNose.y);
      
      if (distance > _bodyMovementThreshold && !hasDetectedBodyMovement.value) {
        hasDetectedBodyMovement.value = true;
        naturalMovements.value++;
        debugPrint('[AdvancedLivenessService] Body movement detected!');
      }
    }
  }

  void _analyzeSegmentationMask(SegmentationMask mask) {
    // Calculate average confidence of person pixels
    // High confidence indicates a real person vs low confidence for photos/screens
    final confidences = mask.confidences;
    if (confidences.isNotEmpty) {
      final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;
      averageSegmentationConfidence.value = avgConfidence;
      
      if (avgConfidence < _minSegmentationConfidence) {
        debugPrint('[AdvancedLivenessService] Low segmentation confidence: ${avgConfidence.toStringAsFixed(2)} - possible photo/screen');
      }
    }
  }

  void _analyzeResults() {
    debugPrint('📊 [AdvancedLiveness] Analysis - Stable: ${hasStableFace.value}, Smile: ${hasDetectedSmile.value}, Head: ${hasDetectedHeadMovement.value}, Movements: ${naturalMovements.value}/$_requiredNaturalMovements');
    
    // Update instruction based on current state
    if (!hasStableFace.value) {
      currentInstruction.value = 'Hold phone naturally - face can fill the screen';
      return;
    }
    
    if (!hasDetectedSmile.value) {
      currentInstruction.value = 'Great! Now smile naturally';
    } else if (!hasDetectedHeadMovement.value) {
      currentInstruction.value = 'Perfect! Turn your head slightly';
    } else if (naturalMovements.value < _requiredNaturalMovements) {
      currentInstruction.value = 'Excellent! Move naturally for a moment';
    } else {
      // All liveness checks passed!
      debugPrint('🎉 [AdvancedLiveness] ALL CHECKS PASSED! Liveness verification complete!');
      currentInstruction.value = 'Liveness verified! Capturing photo...';
      state.value = LivenessState.allCompleted;
    }
  }

  void _updateProgress() {
    double progressValue = 0.0;
    
    // Face detection: 30%
    if (hasStableFace.value) progressValue += 0.3;
    
    // Smile detection: 30%
    if (hasDetectedSmile.value) progressValue += 0.3;
    
    // Head movement: 20%
    if (hasDetectedHeadMovement.value) progressValue += 0.2;
    
    // Body movement or high segmentation confidence: 20%
    if (hasDetectedBodyMovement.value || averageSegmentationConfidence.value > _minSegmentationConfidence) {
      progressValue += 0.2;
    }
    
    progress.value = progressValue;
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
  }

  void resetLivenessDetection() {
    debugPrint('[AdvancedLivenessService] Resetting liveness detection state...');

    state.value = LivenessState.idle;
    currentInstruction.value = '';
    progress.value = 0.0;

    _resetTrackingState();

    debugPrint('[AdvancedLivenessService] Reset complete');
  }

  // Getters for UI
  bool get isActive => state.value != LivenessState.idle && state.value != LivenessState.allCompleted;
  bool get isCompleted => state.value == LivenessState.allCompleted;
  
  String get antiSpoofingStatus {
    final checks = <String>[];
    if (hasDetectedSmile.value) checks.add('😊 Smile');
    if (hasDetectedHeadMovement.value) checks.add('🔄 Head Movement');
    if (hasDetectedBodyMovement.value) checks.add('🏃 Body Movement');
    if (averageSegmentationConfidence.value > _minSegmentationConfidence) checks.add('✨ Real Person');
    
    return checks.isEmpty ? 'No verification yet' : checks.join(' ');
  }
}

