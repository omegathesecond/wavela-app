import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'selfie_controller.dart';
import '../../../../data/services/liveness_service.dart';
import 'dart:math' as math;

class SelfieCapturePage extends GetView<SelfieController> {
  const SelfieCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[SelfieCapturePage] build() called');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Liveness Verification', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: controller.showInstructions,
            icon: const Icon(Icons.help_outline),
          ),
          TextButton(
            onPressed: () => _showSkipDialog(context),
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Real camera preview for liveness detection
                  _buildCameraPreview(),
                  _buildLivenessOverlay(),
                ],
              ),
            ),
            _buildInstructions(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GetBuilder<SelfieController>(
      builder: (controller) {
        if (!controller.isCameraReady.value || controller.cameraService.controller == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.cameraService.controller!.value.previewSize?.height ?? 1,
              height: controller.cameraService.controller!.value.previewSize?.width ?? 1,
              child: CameraPreview(controller.cameraService.controller!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLivenessOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          // Progress indicator
          _buildProgressHeader(),
          
          // Face outline and detection area
          Expanded(
            child: Center(
              child: Obx(() => SizedBox(
                width: 300, // Natural face width
                height: 380, // Proportional height for face shape
                child: CustomPaint(
                  painter: LivenessFaceOutlinePainter(
                    hasStableFace: controller.hasStableFace,
                    livenessState: controller.livenessState,
                    progress: controller.livenessProgress,
                  ),
                  child: Center(
                    child: _buildFaceDetectionIndicator(),
                  ),
                ),
              )),
            ),
          ),
          
          const SizedBox(height: 100), // Space for bottom controls
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Obx(() {
      if (!controller.isLivenessStarted.value) return const SizedBox.shrink();
      
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Advanced Liveness Detection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: controller.livenessProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                controller.livenessState == LivenessState.allCompleted 
                    ? Colors.green 
                    : Colors.blue,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFaceDetectionIndicator() {
    return Obx(() {
      if (!controller.hasStableFace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_outlined,
              color: Colors.white.withValues(alpha: 0.7),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Position your face\nand follow instructions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }

      // Show current challenge icon
      return _buildChallengeIcon();
    });
  }

  Widget _buildChallengeIcon() {
    return Obx(() {
      if (controller.livenessState == LivenessState.allCompleted) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),
            const SizedBox(height: 8),
            Text(
              'Liveness verified!\nCapturing photo...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }

      // Show current detection status
      IconData icon = Icons.security;
      Color color = Colors.blue;
      String status = 'Starting detection...';
      
      if (controller.hasStableFace) {
        icon = Icons.face;
        color = Colors.green;
        status = 'Face detected';
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 50,
          ),
          const SizedBox(height: 8),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.antiSpoofingStatus,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() {
        IconData instructionIcon = Icons.face;
        Color instructionColor = Colors.blue;
        
        // Determine icon and color based on current state
        if (controller.currentInstruction.toLowerCase().contains('smile')) {
          instructionIcon = Icons.sentiment_satisfied;
          instructionColor = Colors.green;
        } else if (controller.currentInstruction.toLowerCase().contains('position')) {
          instructionIcon = Icons.center_focus_strong;
          instructionColor = Colors.orange;
        } else if (controller.currentInstruction.toLowerCase().contains('completed')) {
          instructionIcon = Icons.check_circle;
          instructionColor = Colors.green;
        }
        
        return Column(
          children: [
            // Header with icon and progress
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: instructionColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: instructionColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      instructionIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liveness Detection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: controller.livenessProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(instructionColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(controller.livenessProgress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: instructionColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main instruction
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    controller.currentInstruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.antiSpoofingStatus.isNotEmpty && 
                      !controller.antiSpoofingStatus.contains('No verification'))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        controller.antiSpoofingStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Obx(() {
            if (!controller.isLivenessStarted.value && controller.isCameraReady.value) {
              // Show start button
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.startLivenessDetection,
                      icon: const Icon(Icons.security),
                      label: const Text('Start Liveness Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Camera not ready or processing
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null,
                      child: controller.isProcessing.value 
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : const Text('Initializing...'),
                    ),
                  ),
                ],
              );
            }
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: controller.switchCamera,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                tooltip: 'Switch Camera',
              ),
              IconButton(
                onPressed: controller.showInstructions,
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: 'Instructions',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Skip Liveness Detection?'),
        content: const Text(
          'Liveness detection helps verify that you are a real person. '
          'Skipping this step may reduce security. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offNamed('/verification/result'); // Skip to result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class LivenessFaceOutlinePainter extends CustomPainter {
  final bool hasStableFace;
  final LivenessState livenessState;
  final double progress;

  LivenessFaceOutlinePainter({
    required this.hasStableFace,
    required this.livenessState,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Determine outline color based on state
    Color outlineColor;
    if (livenessState == LivenessState.allCompleted) {
      outlineColor = Colors.green;
    } else if (hasStableFace && livenessState == LivenessState.challengeActive) {
      outlineColor = Colors.blue;
    } else if (hasStableFace) {
      outlineColor = Colors.yellow;
    } else {
      outlineColor = Colors.white.withValues(alpha: 0.7);
    }

    paint.color = outlineColor;

    // Draw face-shaped outline (rounded rectangle for natural face shape)
    final faceRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 10),
      width: size.width * 0.75,  // Wider for natural face proportions
      height: size.height * 0.72, // Taller but well-proportioned
    );

    // Create a face-like rounded rectangle path
    final path = Path();
    final radius = Radius.circular(faceRect.width * 0.25); // More rounded for face-like shape
    
    path.addRRect(RRect.fromRectAndRadius(faceRect, radius));
    canvas.drawPath(path, paint);

    // Draw progress arc if liveness is active
    if (livenessState == LivenessState.challengeActive || 
        livenessState == LivenessState.challengeCompleted) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..color = Colors.blue
        ..strokeCap = StrokeCap.round;

      final progressRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 10),
        width: size.width * 0.8,  // Slightly larger than face rect
        height: size.height * 0.77, // Matching proportions
      );

      canvas.drawArc(
        progressRect,
        -math.pi / 2, // Start from top
        2 * math.pi * progress, // Progress arc
        false,
        progressPaint,
      );
    }

    // Draw corner guides
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = outlineColor.withValues(alpha: 0.5);

    final cornerLength = 20.0;
    final corners = [
      // Top-left
      Offset(faceRect.left - 10, faceRect.top - 10),
      // Top-right  
      Offset(faceRect.right + 10, faceRect.top - 10),
      // Bottom-left
      Offset(faceRect.left - 10, faceRect.bottom + 10),
      // Bottom-right
      Offset(faceRect.right + 10, faceRect.bottom + 10),
    ];

    for (final corner in corners) {
      // Horizontal line
      canvas.drawLine(
        corner,
        Offset(corner.dx + (corner.dx < size.width / 2 ? cornerLength : -cornerLength), corner.dy),
        cornerPaint,
      );
      // Vertical line
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + (corner.dy < size.height / 2 ? cornerLength : -cornerLength)),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(LivenessFaceOutlinePainter oldDelegate) {
    return hasStableFace != oldDelegate.hasStableFace ||
           livenessState != oldDelegate.livenessState ||
           progress != oldDelegate.progress;
  }
}