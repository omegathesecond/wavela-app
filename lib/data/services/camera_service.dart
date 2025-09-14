import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CameraService extends GetxService {
  List<CameraDescription>? cameras;
  CameraController? controller;
  final ImagePicker _picker = ImagePicker();
  
  final RxBool isInitialized = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isTakingPicture = false.obs;
  final Rx<FlashMode> flashMode = FlashMode.off.obs;
  
  bool _isInitializing = false;
  
  @override
  void onInit() {
    super.onInit();
    // Don't initialize cameras here - do it when needed
    debugPrint('[CameraService] Service initialized');
  }
  
  @override
  void onClose() {
    disposeCamera();
    super.onClose();
  }
  
  Future<void> initializeCameras() async {
    try {
      debugPrint('[CameraService] Starting camera initialization...');
      cameras = await availableCameras();
      debugPrint('[CameraService] Found ${cameras?.length ?? 0} cameras');
      if (cameras != null && cameras!.isNotEmpty) {
        await initializeCamera(0); // Default high resolution
      } else {
        debugPrint('[CameraService] No cameras found');
      }
    } catch (e) {
      debugPrint('[CameraService] Error initializing cameras: $e');
    }
  }
  
  Future<bool> ensureCameraInitialized() async {
    if (isInitialized.value && controller != null && controller!.value.isInitialized) {
      return true;
    }
    
    if (_isInitializing) {
      debugPrint('[CameraService] Already initializing, waiting...');
      // Wait for current initialization to complete
      int attempts = 0;
      while (_isInitializing && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return isInitialized.value && controller != null && controller!.value.isInitialized;
    }
    
    debugPrint('[CameraService] Camera not initialized, initializing now...');
    await initializeCameras();
    return isInitialized.value;
  }
  
  Future<void> initializeCamera(int cameraIndex, {ResolutionPreset? resolution}) async {
    if (cameras == null || cameras!.isEmpty) return;
    if (_isInitializing) return;
    
    try {
      _isInitializing = true;
      // Use high resolution by default for clear images, or specified resolution
      final targetResolution = resolution ?? ResolutionPreset.high;
      debugPrint('[CameraService] Initializing camera $cameraIndex with resolution: ${targetResolution.name}...');
      
      // Properly dispose existing controller first
      disposeCamera();
      await Future.delayed(const Duration(milliseconds: 200)); // Give time for cleanup
      
      controller = CameraController(
        cameras![cameraIndex],
        targetResolution,
        enableAudio: false,
        // Use YUV420 for ML Kit compatibility when needed, otherwise auto
        imageFormatGroup: targetResolution == ResolutionPreset.low 
            ? ImageFormatGroup.yuv420  // For ML Kit processing
            : ImageFormatGroup.jpeg,   // For high quality photos
      );
      
      debugPrint('[CameraService] Controller created, initializing...');
      await controller!.initialize();
      
      if (controller!.value.isInitialized) {
        debugPrint('[CameraService] Camera initialized with resolution ${targetResolution.name}, setting flash mode...');
        await controller!.setFlashMode(flashMode.value);
        isInitialized.value = true;
        debugPrint('[CameraService] Camera initialization completed successfully');
      } else {
        throw Exception('Controller failed to initialize properly');
      }
    } catch (e) {
      debugPrint('[CameraService] Error initializing camera: $e');
      isInitialized.value = false;
      disposeCamera(); // Clean up on error
    } finally {
      _isInitializing = false;
    }
  }
  
  Future<void> switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    if (controller == null) return;
    
    try {
      final currentIndex = cameras!.indexOf(controller!.description);
      final newIndex = (currentIndex + 1) % cameras!.length;
      debugPrint('[CameraService] Switching from camera $currentIndex to $newIndex');
      await initializeCamera(newIndex); // Keep same resolution
    } catch (e) {
      debugPrint('[CameraService] Error switching camera: $e');
    }
  }
  
  Future<void> toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;
    
    switch (flashMode.value) {
      case FlashMode.off:
        flashMode.value = FlashMode.auto;
        break;
      case FlashMode.auto:
        flashMode.value = FlashMode.always;
        break;
      case FlashMode.always:
        flashMode.value = FlashMode.off;
        break;
      default:
        flashMode.value = FlashMode.off;
    }
    
    await controller!.setFlashMode(flashMode.value);
  }
  
  Future<XFile?> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return null;
    if (isTakingPicture.value) return null;
    
    try {
      isTakingPicture.value = true;
      final XFile photo = await controller!.takePicture();
      return photo;
    } catch (e) {
      debugPrint('[CameraService] Error taking picture: $e');
      return null;
    } finally {
      isTakingPicture.value = false;
    }
  }
  
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      return image;
    } catch (e) {
      debugPrint('[CameraService] Error picking image from gallery: $e');
      return null;
    }
  }
  
  void startImageStream(Function(CameraImage) onImage) {
    if (controller == null || !controller!.value.isInitialized) {
      debugPrint('⚠️ [CameraService] Cannot start image stream - controller not ready');
      return;
    }
    if (controller!.value.isStreamingImages) {
      debugPrint('ℹ️ [CameraService] Image stream already active');
      return;
    }
    
    debugPrint('🎥 [CameraService] Starting image stream at ${controller!.value.previewSize} resolution');
    controller!.startImageStream(onImage);
  }
  
  void stopImageStream() {
    if (controller == null || !controller!.value.isInitialized) {
      debugPrint('ℹ️ [CameraService] Cannot stop image stream - controller not ready');
      return;
    }
    if (!controller!.value.isStreamingImages) {
      debugPrint('ℹ️ [CameraService] Image stream not active');
      return;
    }
    
    debugPrint('⏹️ [CameraService] Stopping image stream...');
    controller!.stopImageStream();
  }
  
  void disposeCamera() {
    debugPrint('[CameraService] Disposing camera...');
    try {
      if (controller != null) {
        if (controller!.value.isInitialized && controller!.value.isStreamingImages) {
          try {
            controller!.stopImageStream();
            // Give time for stream to fully stop before disposing
            Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            debugPrint('[CameraService] Error stopping image stream: $e');
          }
        }
        controller!.dispose();
        controller = null;
        isInitialized.value = false;
        debugPrint('[CameraService] Camera disposed successfully');
      }
    } catch (e) {
      debugPrint('[CameraService] Error disposing camera: $e');
      controller = null;
      isInitialized.value = false;
    }
  }
  
  CameraDescription? getFrontCamera() {
    if (cameras == null || cameras!.isEmpty) {
      debugPrint('[CameraService] No cameras available for front camera search');
      return null;
    }
    
    try {
      final frontCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      debugPrint('[CameraService] Found front camera: ${frontCamera.name}');
      return frontCamera;
    } catch (e) {
      debugPrint('[CameraService] No front camera found, available cameras:');
      for (int i = 0; i < cameras!.length; i++) {
        debugPrint('  Camera $i: ${cameras![i].name} - ${cameras![i].lensDirection}');
      }
      // Return first available camera as fallback
      return cameras!.isNotEmpty ? cameras!.first : null;
    }
  }
  
  CameraDescription? getBackCamera() {
    if (cameras == null || cameras!.isEmpty) return null;
    
    return cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras!.first,
    );
  }
  
  Future<bool> checkCameraPermission() async {
    return true;
  }
  
  double getAspectRatio() {
    if (controller == null || !controller!.value.isInitialized) {
      return 1.0;
    }
    return controller!.value.aspectRatio;
  }
  
  Size getPreviewSize() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Size(1, 1);
    }
    return controller!.value.previewSize ?? const Size(1, 1);
  }
}