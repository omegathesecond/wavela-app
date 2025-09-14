import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'processing_controller.dart';

class ProcessingPage extends GetView<ProcessingController> {
  const ProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 60),
              Expanded(child: _buildProcessingSteps()),
              const SizedBox(height: 40),
              _buildProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics,
            size: 40,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verifying Your Identity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we process your documents',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProcessingSteps() {
    return Obx(() => Column(
      children: [
        _buildStep(
          icon: Icons.document_scanner,
          title: 'Extracting ID Information',
          description: 'Reading text from your ID documents',
          isCompleted: controller.ocrCompleted.value,
          isActive: controller.currentProcess.value == 'ocr',
        ),
        const SizedBox(height: 30),
        _buildStep(
          icon: Icons.face,
          title: 'Verifying Face Match',
          description: 'Comparing your selfie with ID photo',
          isCompleted: controller.faceMatchCompleted.value,
          isActive: controller.currentProcess.value == 'face',
        ),
        const SizedBox(height: 30),
        _buildStep(
          icon: Icons.security,
          title: 'Liveness Detection',
          description: 'Ensuring you are a real person',
          isCompleted: controller.livenessCompleted.value,
          isActive: controller.currentProcess.value == 'liveness',
        ),
      ],
    ));
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.shade100
                : isActive
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.green)
              : isActive
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      ),
                    )
                  : Icon(icon, color: Colors.grey),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Obx(() => Column(
      children: [
        LinearProgressIndicator(
          value: controller.progress.value,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 12),
        Text(
          '${(controller.progress.value * 100).toInt()}% Complete',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    ));
  }
}