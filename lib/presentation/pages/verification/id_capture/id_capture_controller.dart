import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../data/services/camera_service.dart';
import '../../../../data/services/ml_kit_helper.dart';
import '../verification_controller.dart';

class IDCaptureController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  late final TextRecognizer _textRecognizer;
  
  // Expose camera service for UI access
  CameraService get cameraService => _cameraService;
  
  final RxBool isCameraInitialized = false.obs;
  final RxBool isCardDetected = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxString currentSide = 'front'.obs;
  final RxString instructions = 'Position your ID card within the frame'.obs;
  final RxList<String> capturedSides = <String>[].obs;
  final RxBool showPreview = false.obs;
  final RxString lastCapturedImagePath = ''.obs;
  
  // Store captured image paths
  String? _frontImagePath;
  String? _backImagePath;
  
  // Detection state
  final RxBool isDetecting = false.obs;
  final RxInt framesWithCard = 0.obs;
  final RxInt framesWithoutCard = 0.obs;
  static const int _minFramesForDetection = 3;
  static const int _maxFramesWithoutCard = 30;
  
  // Processing throttling
  bool _isProcessing = false;
  DateTime? _lastProcessTime;

  @override
  void onInit() {
    super.onInit();
    _initializeTextRecognizer();
    initializeCamera();
  }
  
  void _initializeTextRecognizer() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void onClose() {
    debugPrint('[IDCaptureController] Disposing ID capture controller...');
    _cameraService.stopImageStream();
    _cameraService.disposeCamera();
    _textRecognizer.close();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      isCameraInitialized.value = false;
      instructions.value = 'Initializing camera...';
      
      final initialized = await _cameraService.ensureCameraInitialized();
      isCameraInitialized.value = initialized;
      
      if (initialized) {
        instructions.value = 'Position your ID card within the frame';
        _startCardDetection();
      } else {
        instructions.value = 'Camera initialization failed';
      }
    } catch (e) {
      debugPrint('[IDCaptureController] Failed to initialize camera: $e');
      instructions.value = 'Camera initialization failed';
      Get.snackbar(
        'Error', 
        'Failed to initialize camera: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  void toggleFlash() {
    _cameraService.toggleFlash();
    isFlashOn.value = _cameraService.flashMode.value.name == 'always';
  }

  void switchCamera() async {
    await _cameraService.switchCamera();
  }

  void captureImage() async {
    if (!isCameraInitialized.value) return;
    
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        lastCapturedImagePath.value = image.path;
        showPreview.value = true;
        
        // Update instructions for preview
        instructions.value = 'Review the captured image. Retake if needed.';
      }
    } catch (e) {
      debugPrint('[IDCaptureController] Failed to capture image: $e');
      Get.snackbar('Error', 'Failed to capture image: $e');
    }
  }

  void acceptImage() {
    capturedSides.add(currentSide.value);
    showPreview.value = false;
    
    // Save the captured image path for the current side
    if (currentSide.value == 'front') {
      _frontImagePath = lastCapturedImagePath.value;
      debugPrint('[IDCaptureController] Saved front image: $_frontImagePath');
    } else if (currentSide.value == 'back') {
      _backImagePath = lastCapturedImagePath.value;
      debugPrint('[IDCaptureController] Saved back image: $_backImagePath');
    }
    
    if (currentSide.value == 'front' && !capturedSides.contains('back')) {
      // Show flip instruction dialog
      _showFlipInstructionDialog();
    } else {
      // Both sides captured - save to verification controller and proceed
      instructions.value = 'Both sides captured! Proceeding to liveness detection...';
      debugPrint('[IDCaptureController] Both sides captured, saving to verification controller');
      
      // Save images to verification controller
      try {
        final verificationController = Get.find<VerificationController>();
        verificationController.setIDImages(_frontImagePath!, _backImagePath!);
        debugPrint('[IDCaptureController] Successfully saved ID images to verification controller');
      } catch (e) {
        debugPrint('[IDCaptureController] Failed to save images to verification controller: $e');
      }
      
      Future.delayed(const Duration(seconds: 1), () {
        debugPrint('[IDCaptureController] Preparing to navigate to selfie');
        // Stop detection
        _cameraService.stopImageStream();
        isDetecting.value = false;
        
        // Small delay before disposing camera
        Future.delayed(const Duration(milliseconds: 100), () {
          // Dispose camera properly before navigation
          _cameraService.disposeCamera();
          
          Future.delayed(const Duration(milliseconds: 300), () {
            debugPrint('[IDCaptureController] Navigating to /verification/selfie');
            try {
              Get.offNamed('/verification/selfie');
              debugPrint('[IDCaptureController] Navigation to selfie completed');
            } catch (e) {
              debugPrint('[IDCaptureController] Navigation error: $e');
              Get.snackbar('Error', 'Failed to proceed to next step: $e');
            }
          });
        });
      });
    }
  }

  void _showFlipInstructionDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flip_to_back, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Flip Your ID Card'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.credit_card,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Great! Front side captured successfully.',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Now please flip your ID card to show the back side and position it within the camera frame.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure the back side is clearly visible and well-lit',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: _proceedToBackCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ready - Capture Back Side'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _proceedToBackCapture() {
    Get.back(); // Close dialog
    currentSide.value = 'back';
    instructions.value = 'Position the back of your ID card within the frame';
    isCardDetected.value = false; // Reset detection for back side
    framesWithCard.value = 0;
    framesWithoutCard.value = 0;
    _startCardDetection(); // Start detection for back side
  }

  void retakeImage() {
    showPreview.value = false;
    instructions.value = currentSide.value == 'front' 
        ? 'Position your ID card within the frame'
        : 'Position the back of your ID card within the frame';
    isCardDetected.value = false;
    framesWithCard.value = 0;
    framesWithoutCard.value = 0;
    _isProcessing = false;
    _lastProcessTime = null;
    _startCardDetection();
  }

  void _startCardDetection() {
    if (!isCameraInitialized.value || isDetecting.value || showPreview.value) return;
    
    debugPrint('[IDCaptureController] Starting card detection...');
    isDetecting.value = true;
    framesWithCard.value = 0;
    framesWithoutCard.value = 0;
    _isProcessing = false;
    _lastProcessTime = null;
    
    // Start image stream for card detection
    _cameraService.startImageStream((CameraImage image) {
      if (!isDetecting.value || showPreview.value) return;
      _processImageForCardDetection(image);
    });
  }
  
  Future<void> _processImageForCardDetection(CameraImage image) async {
    if (isCardDetected.value || _isProcessing) return;
    
    // Throttle processing to prevent overload (max 1 frame per second)
    if (_lastProcessTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(_lastProcessTime!);
      if (timeSinceLastProcess.inMilliseconds < 1000) {
        return;
      }
    }
    
    _isProcessing = true;
    _lastProcessTime = DateTime.now();
    
    try {
      final inputImage = MLKitHelper.inputImageFromCameraImage(
        image, 
        _cameraService.controller!.description
      );
      
      if (inputImage == null) {
        debugPrint('[IDCaptureController] Failed to convert camera image');
        return;
      }
      
      // Process the image with text recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Check if we have ID card-like text
      final bool hasIDCardText = MLKitHelper.containsIDCardKeywords(recognizedText.text);
      
      if (hasIDCardText && recognizedText.blocks.length >= 2) {
        framesWithCard.value++;
        framesWithoutCard.value = 0;
        
        debugPrint('[IDCaptureController] ID card detected (${framesWithCard.value}/$_minFramesForDetection)');
        
        if (framesWithCard.value >= _minFramesForDetection) {
          // Card detected consistently
          isCardDetected.value = true;
          instructions.value = 'ID card detected! Capturing...';
          
          // Stop detection and capture
          _cameraService.stopImageStream();
          
          // Auto-capture after a short delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (isCardDetected.value && !showPreview.value) {
              captureImage();
            }
          });
        } else {
          instructions.value = 'Detecting card... Hold steady';
        }
      } else {
        framesWithoutCard.value++;
        framesWithCard.value = 0;
        
        if (framesWithoutCard.value > _maxFramesWithoutCard) {
          isCardDetected.value = false;
          instructions.value = currentSide.value == 'front' 
              ? 'Position your ID card within the frame'
              : 'Position the back of your ID card within the frame';
        }
      }
    } catch (e) {
      debugPrint('[IDCaptureController] Error in card detection: $e');
    } finally {
      _isProcessing = false;
    }
  }
}