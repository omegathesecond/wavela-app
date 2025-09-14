import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'liveness_service.dart';
import 'dart:io';
import 'dart:math' as math;

class BiometricService extends GetxService {
  late FaceDetector _faceDetector;
  
  final RxBool isProcessing = false.obs;
  final RxDouble matchConfidence = 0.0.obs;
  final RxString status = ''.obs;
  
  static const double matchThreshold = 0.75;
  static const double livenessThreshold = 0.80;
  
  @override
  void onInit() {
    super.onInit();
    _initializeFaceDetector();
  }
  
  @override
  void onClose() {
    _faceDetector.close();
    super.onClose();
  }
  
  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }
  
  Future<Face?> detectFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        status.value = 'No face detected';
        return null;
      }
      
      if (faces.length > 1) {
        status.value = 'Multiple faces detected';
        return null;
      }
      
      return faces.first;
    } catch (e) {
      status.value = 'Error detecting face: $e';
      return null;
    }
  }
  
  Future<bool> compareFaces(String idImagePath, String selfieImagePath) async {
    if (isProcessing.value) return false;
    
    try {
      isProcessing.value = true;
      status.value = 'Detecting face in ID...';
      
      final idFace = await detectFace(idImagePath);
      if (idFace == null) {
        status.value = 'No face found in ID';
        return false;
      }
      
      status.value = 'Detecting face in selfie...';
      final selfieFace = await detectFace(selfieImagePath);
      if (selfieFace == null) {
        status.value = 'No face found in selfie';
        return false;
      }
      
      status.value = 'Comparing faces...';
      final confidence = _calculateFaceSimilarity(idFace, selfieFace);
      matchConfidence.value = confidence;
      
      if (confidence >= matchThreshold) {
        status.value = 'Face match successful (${(confidence * 100).toStringAsFixed(1)}%)';
        return true;
      } else {
        status.value = 'Face match failed (${(confidence * 100).toStringAsFixed(1)}%)';
        return false;
      }
    } catch (e) {
      status.value = 'Error comparing faces: $e';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
  
  double _calculateFaceSimilarity(Face face1, Face face2) {
    double similarity = 0.0;
    int comparisonCount = 0;
    
    if (face1.headEulerAngleY != null && face2.headEulerAngleY != null) {
      double yawDiff = (face1.headEulerAngleY! - face2.headEulerAngleY!).abs();
      similarity += math.max(0, 1 - (yawDiff / 45));
      comparisonCount++;
    }
    
    if (face1.headEulerAngleZ != null && face2.headEulerAngleZ != null) {
      double rollDiff = (face1.headEulerAngleZ! - face2.headEulerAngleZ!).abs();
      similarity += math.max(0, 1 - (rollDiff / 45));
      comparisonCount++;
    }
    
    final bbox1 = face1.boundingBox;
    final bbox2 = face2.boundingBox;
    double aspectRatio1 = bbox1.width / bbox1.height;
    double aspectRatio2 = bbox2.width / bbox2.height;
    double aspectRatioDiff = (aspectRatio1 - aspectRatio2).abs();
    similarity += math.max(0, 1 - aspectRatioDiff);
    comparisonCount++;
    
    if (face1.landmarks.isNotEmpty && face2.landmarks.isNotEmpty) {
      double landmarkSimilarity = _compareLandmarks(face1.landmarks, face2.landmarks);
      similarity += landmarkSimilarity * 2;
      comparisonCount += 2;
    }
    
    if (face1.smilingProbability != null && face2.smilingProbability != null) {
      double smileDiff = (face1.smilingProbability! - face2.smilingProbability!).abs();
      similarity += math.max(0, 1 - smileDiff) * 0.5;
      comparisonCount++;
    }
    
    return comparisonCount > 0 ? similarity / comparisonCount : 0.0;
  }
  
  double _compareLandmarks(Map<FaceLandmarkType, FaceLandmark?> landmarks1,
                          Map<FaceLandmarkType, FaceLandmark?> landmarks2) {
    double totalSimilarity = 0.0;
    int count = 0;
    
    final importantLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
    ];
    
    for (final landmarkType in importantLandmarks) {
      final landmark1 = landmarks1[landmarkType];
      final landmark2 = landmarks2[landmarkType];
      
      if (landmark1 != null && landmark2 != null) {
        double distance = _calculateDistance(
          landmark1.position.x.toDouble(),
          landmark1.position.y.toDouble(),
          landmark2.position.x.toDouble(),
          landmark2.position.y.toDouble(),
        );
        
        totalSimilarity += math.max(0, 1 - (distance / 100));
        count++;
      }
    }
    
    return count > 0 ? totalSimilarity / count : 0.0;
  }
  
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }
  
  Future<bool> performLivenessCheck(List<String> imagePaths) async {
    if (imagePaths.length < 2) return false;
    
    try {
      isProcessing.value = true;
      status.value = 'Performing liveness check...';
      
      List<Face?> faces = [];
      for (String path in imagePaths) {
        final face = await detectFace(path);
        if (face == null) return false;
        faces.add(face);
      }
      
      bool hasMovement = false;
      bool hasBlinkVariation = false;
      
      for (int i = 1; i < faces.length; i++) {
        final face1 = faces[i - 1]!;
        final face2 = faces[i]!;
        
        if (face1.headEulerAngleY != null && face2.headEulerAngleY != null) {
          double yawDiff = (face1.headEulerAngleY! - face2.headEulerAngleY!).abs();
          if (yawDiff > 5) hasMovement = true;
        }
        
        if (face1.leftEyeOpenProbability != null && face2.leftEyeOpenProbability != null) {
          double blinkDiff = (face1.leftEyeOpenProbability! - face2.leftEyeOpenProbability!).abs();
          if (blinkDiff > 0.3) hasBlinkVariation = true;
        }
      }
      
      bool isLive = hasMovement || hasBlinkVariation;
      status.value = isLive ? 'Liveness check passed' : 'Liveness check failed';
      return isLive;
      
    } catch (e) {
      status.value = 'Error in liveness check: $e';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
  
  bool validateFacePosition(Face face, Size imageSize) {
    final bbox = face.boundingBox;
    
    double faceWidthRatio = bbox.width / imageSize.width;
    // double faceHeightRatio = bbox.height / imageSize.height; // Currently unused
    
    if (faceWidthRatio < 0.2 || faceWidthRatio > 0.8) {
      status.value = 'Face too small or too large';
      return false;
    }
    
    double centerX = (bbox.left + bbox.width / 2) / imageSize.width;
    double centerY = (bbox.top + bbox.height / 2) / imageSize.height;
    
    if (centerX < 0.3 || centerX > 0.7 || centerY < 0.3 || centerY > 0.7) {
      status.value = 'Face not centered';
      return false;
    }
    
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 30) {
      status.value = 'Face not straight (turn head forward)';
      return false;
    }
    
    if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 30) {
      status.value = 'Face tilted (keep head straight)';
      return false;
    }
    
    status.value = 'Face position OK';
    return true;
  }

  /// Verifies liveness detection result and integrates with overall verification
  Future<bool> verifyLivenessResult(LivenessResult livenessResult, String imagePath) async {
    try {
      isProcessing.value = true;
      status.value = 'Verifying liveness result...';

      // Check if liveness was successful
      if (!livenessResult.success) {
        status.value = 'Liveness verification failed: ${livenessResult.message}';
        return false;
      }

      // Check confidence threshold
      if (livenessResult.confidence < livenessThreshold) {
        status.value = 'Liveness confidence too low: ${(livenessResult.confidence * 100).toInt()}%';
        return false;
      }

      // Verify the captured image quality
      final face = await detectFace(imagePath);
      if (face == null) {
        status.value = 'No face detected in captured image';
        return false;
      }

      // Additional face quality checks
      if (!_validateFaceQuality(face)) {
        return false;
      }

      status.value = 'Liveness verification completed successfully';
      matchConfidence.value = livenessResult.confidence;
      return true;

    } catch (e) {
      status.value = 'Error verifying liveness: $e';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  bool _validateFaceQuality(Face face) {
    // Check face angle constraints
    if (face.headEulerAngleX != null && face.headEulerAngleX!.abs() > 25) {
      status.value = 'Face angle too extreme (vertical)';
      return false;
    }

    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 25) {
      status.value = 'Face angle too extreme (horizontal)';
      return false;
    }

    // Check eye detection
    if (face.leftEyeOpenProbability == null || face.rightEyeOpenProbability == null) {
      status.value = 'Eyes not properly detected';
      return false;
    }

    // Ensure eyes are open in final capture
    if (face.leftEyeOpenProbability! < 0.5 || face.rightEyeOpenProbability! < 0.5) {
      status.value = 'Eyes should be open in final capture';
      return false;
    }

    return true;
  }

  /// Get enhanced verification result with liveness data
  Map<String, dynamic> getVerificationResult(LivenessResult? livenessResult) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'confidence': matchConfidence.value,
      'status': status.value,
      'liveness': livenessResult != null ? {
        'success': livenessResult.success,
        'confidence': livenessResult.confidence,
        'message': livenessResult.message,
        'challenges_completed': livenessResult.completedChallenges.map((c) => c.toString()).toList(),
        'total_challenges': livenessResult.completedChallenges.length,
      } : null,
      'verification_method': 'ML_Kit_with_liveness',
      'security_level': livenessResult?.success == true ? 'high' : 'medium',
    };
  }
}