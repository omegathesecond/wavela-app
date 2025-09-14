import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/camera_service.dart';
import '../../../../data/services/advanced_liveness_service.dart';
import '../../../../data/services/liveness_service.dart';
import '../verification_controller.dart';

class SelfieController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  final AdvancedLivenessService _livenessService = Get.find<AdvancedLivenessService>();
  
  // Expose services for UI access
  CameraService get cameraService => _cameraService;
  AdvancedLivenessService get livenessService => _livenessService;
  
  final RxBool canCapture = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isCameraReady = false.obs;
  final RxBool isLivenessStarted = false.obs;
  final RxBool hasCompletedLiveness = false.obs;
  
  // Face detection state
  final RxBool hasFaceDetected = false.obs;
  
  // Processing throttling
  bool _isProcessingFace = false;
  DateTime? _lastFrameProcessTime;
  int _droppedFrameCount = 0;
  
  // Auto-retry logic
  Timer? _detectionTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const int _detectionTimeoutSeconds = 15;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[SelfieController] Initializing selfie controller...');
    // Add a small delay to ensure previous page cleanup is complete
    Future.delayed(const Duration(milliseconds: 500), () {
      initializeFrontCamera();
    });
  }

  @override
  void onClose() {
    debugPrint('[SelfieController] Disposing selfie controller...');
    _detectionTimer?.cancel();
    
    // Stop image stream with error handling
    try {
      _cameraService.stopImageStream();
    } catch (e) {
      debugPrint('[SelfieController] Error stopping image stream: $e');
    }
    
    // Wait a bit before disposing camera to prevent buffer issues
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        _cameraService.disposeCamera();
      } catch (e) {
        debugPrint('[SelfieController] Error disposing camera: $e');
      }
    });
    
    _livenessService.resetLivenessDetection();
    super.onClose();
  }

  Future<void> initializeFrontCamera() async {
    try {
      isCameraReady.value = false;
      
      // First ensure cameras are initialized
      if (_cameraService.cameras == null || _cameraService.cameras!.isEmpty) {
        debugPrint('[SelfieController] Cameras not initialized, initializing now...');
        await _cameraService.initializeCameras();
      }
      
      final frontCamera = _cameraService.getFrontCamera();
      if (frontCamera != null) {
        final frontIndex = _cameraService.cameras!.indexOf(frontCamera);
        debugPrint('[SelfieController] Found front camera at index $frontIndex');
        await _cameraService.initializeCamera(frontIndex, resolution: ResolutionPreset.low);
        isCameraReady.value = true;
        update(); // Notify GetBuilder
        
        // Start image stream for liveness detection
        await _startImageStream();
        
        // Automatically start liveness detection after camera is ready
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (isCameraReady.value && !isLivenessStarted.value) {
            startLivenessDetection();
          }
        });
      } else {
        isCameraReady.value = false;
        debugPrint('[SelfieController] No front camera found. Available cameras: ${_cameraService.cameras?.length ?? 0}');
        Get.snackbar(
          'Error', 
          'Front camera not found. Please ensure your device has a front-facing camera.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('[SelfieController] Camera initialization failed: $e');
      isCameraReady.value = false;
      Get.snackbar(
        'Error', 
        'Failed to initialize camera: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraService.controller?.value.isStreamingImages == true) {
      _cameraService.stopImageStream();
    }
    
    debugPrint('📹 [SelfieController] Starting image stream for liveness detection...');
    _cameraService.startImageStream((CameraImage image) {
      if (isLivenessStarted.value && !hasCompletedLiveness.value) {
        // Aggressive frame dropping to prevent buffer overflow
        final now = DateTime.now();
        if (_lastFrameProcessTime != null && 
            now.difference(_lastFrameProcessTime!).inMilliseconds < 1000) {
          _droppedFrameCount++;
          if (_droppedFrameCount % 30 == 0) {
            debugPrint('⚡ [SelfieController] Dropped $_droppedFrameCount frames to prevent buffer overflow');
          }
          return; // Drop this frame
        }
        
        _lastFrameProcessTime = now;
        debugPrint('🎬 [SelfieController] Processing frame for liveness detection...');
        _processFaceDetection(image);
      }
    });
  }

  void startLivenessDetection() {
    if (!isCameraReady.value || isLivenessStarted.value) return;
    
    isLivenessStarted.value = true;
    hasFaceDetected.value = false;
    _isProcessingFace = false;
    
    // Start proper liveness detection with challenges
    _livenessService.startLivenessDetection();
    
    // Start auto-retry timer
    _startDetectionTimer();
  }
  
  void _startDetectionTimer() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(Duration(seconds: _detectionTimeoutSeconds), () {
      _handleDetectionTimeout();
    });
  }
  
  void _handleDetectionTimeout() {
    if (hasCompletedLiveness.value) return; // Already completed
    
    _retryCount++;
    debugPrint('[SelfieController] Detection timeout, retry $_retryCount/$_maxRetries');
    
    if (_retryCount < _maxRetries) {
      // Auto-retry with helpful message
      Get.showSnackbar(GetSnackBar(
        message: 'Retrying detection... ($_retryCount/$_maxRetries)',
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.TOP,
      ));
      
      _resetLivenessDetection();
      Future.delayed(Duration(milliseconds: 1000), () {
        if (!hasCompletedLiveness.value) {
          startLivenessDetection();
        }
      });
    } else {
      // Max retries reached, show helpful guidance
      _showDetectionGuidance();
    }
  }
  
  void _showDetectionGuidance() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Need Help?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Having trouble with detection? Try these tips:'),
            SizedBox(height: 12),
            _buildTipItem('💡', 'Ensure good lighting on your face'),
            _buildTipItem('📱', 'Hold phone at eye level'),
            _buildTipItem('👀', 'Look directly at camera'),
            _buildTipItem('😊', 'Keep face centered in circle'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _retryCount = 0; // Reset retry count
              _resetLivenessDetection();
              Future.delayed(Duration(milliseconds: 500), () {
                startLivenessDetection();
              });
            },
            child: Text('Try Again'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }
  
  Future<void> _processFaceDetection(CameraImage image) async {
    if (hasCompletedLiveness.value || _isProcessingFace) return;
    
    _isProcessingFace = true;
    
    try {
      // Use the proper liveness detection service instead of basic face detection
      await _livenessService.processFrame(image, _cameraService.controller!.description);
      
      // Update our local state based on liveness service state
      hasFaceDetected.value = _livenessService.hasStableFace.value;
      
      // Check if liveness detection is completed
      if (_livenessService.isCompleted && !hasCompletedLiveness.value) {
        debugPrint('🎊 [SelfieController] LIVENESS DETECTION COMPLETED! Preparing to capture final photo...');
        hasCompletedLiveness.value = true;
        
        // Cancel timer and reset retry count on success
        _detectionTimer?.cancel();
        _retryCount = 0;
        
        // Stop image stream and capture selfie
        debugPrint('📷 [SelfieController] Stopping image stream and capturing final selfie...');
        _cameraService.stopImageStream();
        
        Future.delayed(const Duration(milliseconds: 800), () {
          _onLivenessCompleted();
        });
      }
      
    } catch (e) {
      debugPrint('[SelfieController] Error in liveness detection: $e');
    } finally {
      _isProcessingFace = false;
    }
  }

  void _onLivenessCompleted() async {
    try {
      isProcessing.value = true;
      
      // Take final photo
      final image = await _cameraService.takePicture();
      if (image != null) {
        
        // Save selfie to verification controller
        try {
          final verificationController = Get.find<VerificationController>();
          verificationController.setSelfieImage(image.path);
          debugPrint('[SelfieController] Successfully saved selfie image: ${image.path}');
        } catch (e) {
          debugPrint('[SelfieController] Failed to save selfie: $e');
        }
        
        // Show simplified completion dialog
        _showSimplifiedCompletionDialog();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture selfie: $e');
      _resetLivenessDetection();
    } finally {
      isProcessing.value = false;
    }
  }
  
  void _showSimplifiedCompletionDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Selfie Captured!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your selfie has been successfully captured.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photo captured successfully',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offNamed('/verification/result'); // Go to result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue to Results'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }


  void retryLivenessDetection() {
    _resetLivenessDetection();
    Future.delayed(Duration(milliseconds: 500), () {
      startLivenessDetection();
    });
  }

  void _resetLivenessDetection() {
    isLivenessStarted.value = false;
    hasCompletedLiveness.value = false;
    isProcessing.value = false;
    _detectionTimer?.cancel();
    
    // Stop image stream before resetting to prevent buffer issues
    try {
      _cameraService.stopImageStream();
    } catch (e) {
      debugPrint('[SelfieController] Error stopping stream during reset: $e');
    }
    
    // Reset frame processing state
    _lastFrameProcessTime = null;
    _droppedFrameCount = 0;
    _isProcessingFace = false;
    
    _livenessService.resetLivenessDetection();
  }

  void switchCamera() async {
    isCameraReady.value = false;
    await _cameraService.switchCamera();
    isCameraReady.value = true;
    update(); // Notify GetBuilder
    
    // Restart image stream
    if (isLivenessStarted.value) {
      await _startImageStream();
    }
  }

  void showInstructions() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Liveness Detection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Liveness Detection will verify you\'re real using:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            _buildInstructionItem(Icons.sentiment_satisfied, 'Smile detection (prevents photos)'),
            _buildInstructionItem(Icons.rotate_left, 'Natural head movement'),
            _buildInstructionItem(Icons.directions_walk, 'Body movement analysis'),
            _buildInstructionItem(Icons.blur_on, 'Depth perception check'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Anti-Spoofing Protection:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Multi-layer detection prevents photo spoofing'),
                  Text('• Real-time face, pose, and depth analysis'),
                  Text('• Ensure good lighting on your face'),
                  Text('• Keep your face centered and move naturally'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  // Getters for UI
  String get currentInstruction => _livenessService.currentInstruction.value;
  double get livenessProgress => _livenessService.progress.value;
  LivenessState get livenessState => _livenessService.state.value;
  bool get hasStableFace => _livenessService.hasStableFace.value;
  String get antiSpoofingStatus => _livenessService.antiSpoofingStatus;
}