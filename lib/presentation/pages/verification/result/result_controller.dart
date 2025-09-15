import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/verification_api_service.dart';
import '../verification_controller.dart';

enum VerificationResult {
  processing,
  success,
  failed,
}

class ResultController extends GetxController {
  final RxBool isProcessing = true.obs;
  final RxString processingStatus = 'Starting verification...'.obs;
  final RxDouble progress = 0.0.obs;
  final Rx<VerificationResult> verificationResult = VerificationResult.processing.obs;
  
  final RxString verificationId = ''.obs;
  final RxString jobId = ''.obs;
  final RxString completionTime = ''.obs;
  final RxInt confidenceScore = 0.obs;
  final RxBool showRetryOption = false.obs;
  
  late VerificationApiService _verificationApi;
  late VerificationController _verificationController;

  @override
  void onInit() {
    super.onInit();
    _verificationApi = Get.find<VerificationApiService>();
    _verificationController = Get.find<VerificationController>();
    startVerificationProcess();
  }

  void startVerificationProcess() async {
    try {
      debugPrint('🚀 [ResultController] Starting real API verification process...');
      
      final userModel = _verificationController.userModel;
      final documentType = _verificationController.selectedDocumentType.value;
      
      // Validate we have all required data
      if (userModel.idFrontImage == null || userModel.idBackImage == null || userModel.selfieImage == null) {
        throw Exception('Missing required images for verification');
      }
      
      // Start the verification process
      final result = await _verificationApi.startKYCVerification(
        idFrontPath: userModel.idFrontImage!,
        idBackPath: userModel.idBackImage!,
        selfiePath: userModel.selfieImage!,
        metadata: {
          'documentType': documentType,
          'timestamp': DateTime.now().toIso8601String(),
        },
        onProgress: (progressInfo) {
          debugPrint('📊 [ResultController] Progress: ${progressInfo.stage} - ${progressInfo.message}');

          // Handle timeout scenario
          if (progressInfo.stage == 'timeout') {
            verificationResult.value = VerificationResult.processing;
            processingStatus.value = 'Verification is taking longer than usual. You can check again or contact support.';
            progress.value = 0.8;
            isProcessing.value = false;
            showRetryOption.value = true;
            return;
          }

          // Simplify the status messages for better UX
          switch (progressInfo.stage) {
            case 'uploading':
              if (progressInfo.progress < 0.2) {
                processingStatus.value = 'Uploading your documents...';
              } else {
                processingStatus.value = 'Documents uploaded successfully';
              }
              break;
            case 'processing':
              processingStatus.value = 'Verifying your documents...';
              break;
            default:
              processingStatus.value = 'Verifying your documents...';
          }

          progress.value = progressInfo.progress;
        },
      );
      
      // Handle final result
      jobId.value = result.jobId;
      verificationId.value = result.verificationId;
      completionTime.value = _formatDateTime(result.completedAt);
      
      if (result.isSuccessful) {
        verificationResult.value = VerificationResult.success;
        confidenceScore.value = 95; // Could come from API in the future
        processingStatus.value = 'Documents verified successfully!';
        progress.value = 1.0;
        isProcessing.value = false;
      } else if (result.status.name.contains('manual') || result.status.name.contains('review') || result.status.name.contains('pending')) {
        // Don't expose manual review to client - just show as processing
        verificationResult.value = VerificationResult.processing;
        processingStatus.value = 'Your verification is being processed...';
        progress.value = 0.8; // Show as nearly complete but still processing
        isProcessing.value = true; // Keep showing as processing
      } else {
        verificationResult.value = VerificationResult.failed;
        processingStatus.value = result.message.isNotEmpty ? result.message : 'Verification failed';
        progress.value = 1.0;
        isProcessing.value = false;
      }
      
      debugPrint('✅ [ResultController] Verification completed with result: ${verificationResult.value}');
      
    } catch (e) {
      debugPrint('❌ [ResultController] Verification failed: $e');

      // Handle timeout specifically
      if (e.toString().contains('timeout')) {
        verificationResult.value = VerificationResult.processing;
        processingStatus.value = 'Verification is taking longer than usual. You can check again or contact support.';
        progress.value = 0.8;
        isProcessing.value = false;
        showRetryOption.value = true;
        return;
      }

      verificationResult.value = VerificationResult.failed;
      processingStatus.value = 'Verification failed: ${e.toString()}';
      progress.value = 0.0;
      isProcessing.value = false;

      // Show error dialog for non-timeout errors
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Verification Error'),
            ],
          ),
          content: Text(
            'We encountered an error during verification:\n\n${e.toString()}\n\nPlease try again or contact support if the problem persists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void retryVerification() {
    showRetryOption.value = false;
    isProcessing.value = true;
    progress.value = 0.0;
    processingStatus.value = 'Restarting verification...';
    startVerificationProcess();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void goToHome() {
    Get.offAllNamed('/home');
  }

  void shareResult() {
    if (verificationResult.value == VerificationResult.success) {
      Get.snackbar(
        'Success',
        'Verification result shared successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void contactSupport() {
    Get.dialog(
      AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For assistance with your verification, please contact:\n\n'
          'Email: support@wavela.com\n'
          'Phone: +268 123 4567\n'
          'Hours: Mon-Fri 9AM-5PM',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}