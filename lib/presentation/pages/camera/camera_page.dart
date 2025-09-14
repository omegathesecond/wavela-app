import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_controller.dart';

class CameraPage extends GetView<CameraPageController> {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildCameraPreview(),
                  _buildOverlay(),
                ],
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Obx(() => Column(
        children: [
          Text(
            _getStepTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepInstruction(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (controller.currentStep.value + 1) / 3,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      )),
    );
  }

  Widget _buildCameraPreview() {
    return Obx(() {
      if (!controller.isCameraInitialized.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      
      return controller.cameraPreview;
    });
  }

  Widget _buildOverlay() {
    return Obx(() {
      if (controller.currentStep.value < 2) {
        // ID Card overlay
        return Center(
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Align ID card here',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      } else {
        // Face overlay for selfie
        return Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'Position face here',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    });
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: controller.currentStep.value > 0 ? controller.previousStep : null,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          ),
          GestureDetector(
            onTap: controller.takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera,
                color: Colors.black,
                size: 40,
              ),
            ),
          ),
          Obx(() => controller.currentStep.value < 2
              ? IconButton(
                  onPressed: controller.nextStep,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
                )
              : IconButton(
                  onPressed: controller.allPhotosTaken.value ? controller.processPhotos : null,
                  icon: Icon(
                    Icons.check,
                    color: controller.allPhotosTaken.value ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                )),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (controller.currentStep.value) {
      case 0:
        return 'Scan ID Front';
      case 1:
        return 'Scan ID Back';
      case 2:
        return 'Take Selfie';
      default:
        return 'Capture Photo';
    }
  }

  String _getStepInstruction() {
    switch (controller.currentStep.value) {
      case 0:
        return 'Place the front of your ID card within the frame';
      case 1:
        return 'Place the back of your ID card within the frame';
      case 2:
        return 'Look directly at the camera for verification';
      default:
        return 'Follow the instructions';
    }
  }
}