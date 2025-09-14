import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

class CameraPageController extends GetxController {
  late CameraController _cameraController;
  final RxInt currentStep = 0.obs;
  final RxBool isCameraInitialized = false.obs;
  final RxBool allPhotosTaken = false.obs;
  
  final List<File?> capturedPhotos = [null, null, null]; // front, back, selfie
  final List<String> stepNames = ['ID Front', 'ID Back', 'Selfie'];
  
  Widget get cameraPreview => CameraPreview(_cameraController);

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  @override
  void onClose() {
    _cameraController.dispose();
    super.onClose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
      );
      
      await _cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar('Camera Error', 'Failed to initialize camera: $e');
    }
  }

  Future<void> takePicture() async {
    if (!_cameraController.value.isInitialized) return;
    
    try {
      final XFile image = await _cameraController.takePicture();
      capturedPhotos[currentStep.value] = File(image.path);
      
      Get.snackbar(
        'Photo Captured',
        '${stepNames[currentStep.value]} captured successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
      
      // Auto-advance to next step
      if (currentStep.value < 2) {
        nextStep();
      } else {
        _checkAllPhotos();
      }
    } catch (e) {
      Get.snackbar('Capture Error', 'Failed to take picture: $e');
    }
  }

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
      _switchCamera();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      _switchCamera();
    }
  }

  void _switchCamera() async {
    if (currentStep.value == 2) {
      // Switch to front camera for selfie
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      await _cameraController.dispose();
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );
      await _cameraController.initialize();
    }
  }

  void _checkAllPhotos() {
    allPhotosTaken.value = capturedPhotos.every((photo) => photo != null);
  }

  Future<void> processPhotos() async {
    if (!allPhotosTaken.value) {
      Get.snackbar('Error', 'Please capture all required photos');
      return;
    }

    // Pass photos to processing page
    Get.toNamed('/processing', arguments: {
      'idFront': capturedPhotos[0],
      'idBack': capturedPhotos[1], 
      'selfie': capturedPhotos[2],
    });
  }
}