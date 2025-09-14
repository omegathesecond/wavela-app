import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'result_controller.dart';

class ResultPage extends GetView<ResultController> {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultHeader(),
              const SizedBox(height: 40),
              Expanded(child: _buildResultDetails()),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Obx(() => Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: controller.isVerificationSuccessful.value 
                ? Colors.green.shade50 
                : Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            controller.isVerificationSuccessful.value 
                ? Icons.check_circle 
                : Icons.error,
            size: 60,
            color: controller.isVerificationSuccessful.value 
                ? Colors.green.shade600 
                : Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          controller.isVerificationSuccessful.value 
              ? 'Verification Successful!' 
              : 'Verification Failed',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: controller.isVerificationSuccessful.value 
                ? Colors.green.shade700 
                : Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.isVerificationSuccessful.value
              ? 'Your identity has been successfully verified'
              : 'We were unable to verify your identity',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  Widget _buildResultDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Extracted Information', _buildExtractedData()),
          const SizedBox(height: 30),
          _buildSection('Verification Results', _buildVerificationResults()),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildExtractedData() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.extractedData.isNotEmpty) ...[
            const Text(
              'ID Document Data:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              controller.extractedData['frontText'] ?? 'No data extracted',
              style: const TextStyle(fontSize: 14),
            ),
          ] else
            const Text(
              'No data extracted',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    ));
  }

  Widget _buildVerificationResults() {
    return Obx(() => Column(
      children: [
        _buildVerificationItem(
          'Face Match',
          controller.faceMatchResult['match'] ?? false,
          'Confidence: ${controller.faceMatchResult['confidence'] ?? 0}%',
        ),
        const SizedBox(height: 12),
        _buildVerificationItem(
          'Liveness Detection', 
          controller.livenessResult['isLive'] ?? false,
          'Confidence: ${controller.livenessResult['confidence'] ?? 0}%',
        ),
      ],
    ));
  }

  Widget _buildVerificationItem(String title, bool passed, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passed ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error,
            color: passed ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.startNewVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start New Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: controller.shareResults,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Share Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}