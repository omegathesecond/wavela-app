import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'result_controller.dart';

class ResultPage extends GetView<ResultController> {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            if (controller.isProcessing.value) {
              return _buildProcessingView();
            } else {
              return _buildResultView();
            }
          }),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Simple progress circle
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Verifying Documents',
          style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we verify your documents...',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Obx(() => Text(
          controller.processingStatus.value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 32),
        // Show retry button if processing timed out
        Obx(() => controller.showRetryOption.value
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: controller.retryVerification,
                  child: const Text('Check Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.contactSupport,
                  child: const Text('Contact Support'),
                ),
              ],
            )
          : const SizedBox.shrink()),
      ],
    );
  }


  Widget _buildResultView() {
    final isSuccess = controller.verificationResult.value == VerificationResult.success;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildResultIcon(isSuccess),
        const SizedBox(height: 32),
        Text(
          _getResultTitle(),
          style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _getResultMessage(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (isSuccess) _buildSuccessDetails(),
        if (!isSuccess) _buildFailureActions(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildResultIcon(bool isSuccess) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        size: 60,
        color: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  String _getResultTitle() {
    switch (controller.verificationResult.value) {
      case VerificationResult.success:
        return 'Verification Successful!';
      case VerificationResult.failed:
        return 'Verification Failed';
      case VerificationResult.processing:
        return 'Processing...';
    }
  }

  String _getResultMessage() {
    switch (controller.verificationResult.value) {
      case VerificationResult.success:
        return 'Your identity has been successfully verified. You can now access all services.';
      case VerificationResult.failed:
        return 'We could not verify your identity. Please try again or contact support.';
      case VerificationResult.processing:
        return 'Your verification is being processed. Please wait...';
    }
  }

  Widget _buildSuccessDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Verification ID', controller.verificationId.value),
          _buildDetailRow('Completed', controller.completionTime.value),
          _buildDetailRow('Confidence Score', '${controller.confidenceScore.value}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFailureActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Common Issues:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Poor lighting in photos'),
          const Text('• Blurry or unclear documents'),
          const Text('• Face not clearly visible'),
          const Text('• Fingerprint quality too low'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.retryVerification,
            child: const Text('Try Again'),
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
            onPressed: controller.goToHome,
            child: const Text('Go to Home'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: controller.shareResult,
            child: const Text('Share Result'),
          ),
        ),
        if (controller.verificationResult.value != VerificationResult.success) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: controller.contactSupport,
              child: const Text('Contact Support'),
            ),
          ),
        ],
      ],
    );
  }
}