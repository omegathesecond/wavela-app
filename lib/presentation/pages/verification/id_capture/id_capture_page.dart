import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'id_capture_controller.dart';

class IDCapturePage extends GetView<IDCaptureController> {
  const IDCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture ID Card'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.showPreview.value) {
                  return _buildPreviewScreen(context);
                } else if (controller.isCameraInitialized.value) {
                  return _buildCameraView(context);
                } else {
                  return _buildLoadingView();
                }
              }),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real camera preview with proper aspect ratio
                controller.cameraService.controller != null && 
                controller.cameraService.controller!.value.isInitialized
                    ? ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width * 
                                     controller.cameraService.controller!.value.aspectRatio,
                              child: CameraPreview(controller.cameraService.controller!),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Initializing Camera...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                _buildCameraOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Obx(() => Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.currentSide.value == 'front' ? Icons.credit_card : Icons.flip_to_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Step ${controller.currentSide.value == 'front' ? '1' : '2'} of 2',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.currentSide.value == 'front' 
                      ? 'Capture ID Card Front'
                      : 'Now Flip and Capture Back',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.currentSide.value == 'front'
                      ? 'Position your ID card within the frame below'
                      : 'Flip your card and align the back side',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: CardOverlayPainter(),
                      size: Size(280, 160),
                    ),
                    // Corner guides to help with alignment
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 3),
                            left: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 3),
                            right: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3),
                            left: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3),
                            right: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom status area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Position your card and tap capture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.instructions.value,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildPreviewScreen(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          // Preview header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.preview, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Preview - ${controller.currentSide.value == 'front' ? 'Front' : 'Back'} Side',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review the captured image quality',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Preview image
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: controller.lastCapturedImagePath.value.isNotEmpty
                      ? Image.file(
                          File(controller.lastCapturedImagePath.value),
                          fit: BoxFit.contain,
                        )
                      : Container(
                          width: 300,
                          height: 200,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Text(
                              'No image captured',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          
          // Preview controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.retakeImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: controller.acceptImage,
                  icon: const Icon(Icons.check),
                  label: Text(controller.currentSide.value == 'front' ? 'Next' : 'Finish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera...'),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: controller.toggleFlash,
                icon: Obx(() => Icon(
                  controller.isFlashOn.value 
                      ? Icons.flash_on 
                      : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                )),
              ),
              GestureDetector(
                onTap: controller.captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Get.theme.primaryColor,
                    size: 32,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.switchCamera,
                icon: const Icon(
                  Icons.flip_camera_android,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
            'Side: ${controller.currentSide.value.toUpperCase()} (${controller.capturedSides.length}/2)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          )),
        ],
      ),
    );
  }
}

class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final cornerLength = 20.0;
    final cornerWidth = 3.0;
    
    // Draw corner guides
    final corners = [
      Offset(0, 0), // Top-left
      Offset(size.width, 0), // Top-right
      Offset(0, size.height), // Bottom-left
      Offset(size.width, size.height), // Bottom-right
    ];
    
    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromLTWH(corner.dx - cornerWidth/2, corner.dy - cornerWidth/2, 
                     cornerLength, cornerWidth),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(corner.dx - cornerWidth/2, corner.dy - cornerWidth/2, 
                     cornerWidth, cornerLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}