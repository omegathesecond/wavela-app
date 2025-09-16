import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/verification_api_service.dart';
import '../../../../data/services/api_service.dart';
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

  // Verified user information
  final RxString verifiedName = ''.obs;
  final RxString verifiedSurname = ''.obs;
  final RxString verifiedIdNumber = ''.obs;
  final RxString verifiedDateOfBirth = ''.obs;
  final RxString verifiedSex = ''.obs;
  
  late VerificationApiService _verificationApi;
  late ApiService _apiService;
  late VerificationController _verificationController;

  @override
  void onInit() {
    super.onInit();
    _verificationApi = Get.find<VerificationApiService>();
    _apiService = Get.find<ApiService>();

    // Check if this is a test verification
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments?['isTestVerification'] == true) {
      debugPrint('🧪 [ResultController] Test verification mode detected');
      _startTestVerificationPolling(arguments!);
    } else {
      debugPrint('🚀 [ResultController] Normal verification mode - using captured images');
      try {
        _verificationController = Get.find<VerificationController>();
        startVerificationProcess();
      } catch (e) {
        debugPrint('❌ [ResultController] VerificationController not found: $e');
        Get.snackbar(
          'Error',
          'Verification data not found. Please restart the verification process.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.offAllNamed('/home');
      }
    }
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

        // Extract user info from verification result
        _extractVerifiedUserInfoFromResult(result.results);
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

  void _startTestVerificationPolling(Map<String, dynamic> arguments) async {
    try {
      debugPrint('🧪 [ResultController] Starting test verification polling...');

      final jobId = arguments['jobId'] as String;
      final verificationId = arguments['verificationId'] as String;

      this.jobId.value = jobId;
      this.verificationId.value = verificationId;

      processingStatus.value = 'Processing test verification...';
      progress.value = 0.2;

      // Poll job status
      const maxAttempts = 12;
      const pollInterval = Duration(seconds: 5);

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          // Use direct API call instead of the service method
          final response = await _apiService.get('/jobs/$jobId');
          final jobData = response.data['data'] as Map<String, dynamic>;

          // Update progress
          final progressValue = 0.2 + (0.8 * (attempt / maxAttempts));
          progress.value = progressValue;

          // Get current stage and status from API response
          final currentStage = jobData['currentStage'] as String? ?? 'submitted';
          final currentStatus = jobData['currentStatus'] as String? ?? jobData['status'] as String? ?? 'pending';

          // Update status based on job stage
          switch (currentStage) {
            case 'submitted':
              processingStatus.value = 'Documents received and queued...';
              break;
            case 'ocr_processing':
              processingStatus.value = 'Processing document information...';
              break;
            case 'face_verification':
              processingStatus.value = 'Verifying selfie against ID document...';
              break;
            case 'aml_check':
            case 'final_review':
              processingStatus.value = 'Final review in progress...';
              break;
            case 'completed':
              processingStatus.value = 'Verification completed successfully!';
              break;
          }

          debugPrint('🔍 [ResultController] Job status: $currentStatus, stage: $currentStage');

          // Check if job is complete
          if (currentStatus == 'completed') {
            verificationResult.value = VerificationResult.success;
            processingStatus.value = 'Test verification completed successfully!';
            progress.value = 1.0;
            isProcessing.value = false;
            confidenceScore.value = 95;
            completionTime.value = _formatDateTime(DateTime.now());

            // Extract user information from job data for display
            _extractVerifiedUserInfo(jobData);
            return;
          } else if (currentStatus == 'rejected' || currentStatus == 'expired') {
            verificationResult.value = VerificationResult.failed;
            processingStatus.value = 'Test verification failed';
            progress.value = 1.0;
            isProcessing.value = false;
            return;
          } else if (currentStatus == 'on_hold') {
            // Manual review case - show as processing but taking longer
            processingStatus.value = 'Verification will take longer than normal - you\'ll be notified when complete';
            progress.value = 0.8;
          }

          // Wait before next poll
          await Future.delayed(pollInterval);
        } catch (e) {
          debugPrint('❌ [ResultController] Polling attempt $attempt failed: $e');
          if (attempt == maxAttempts - 1) {
            throw Exception('Failed to get job status after $maxAttempts attempts: $e');
          }
        }
      }

      // Timeout case
      verificationResult.value = VerificationResult.processing;
      processingStatus.value = 'Test verification is taking longer than expected';
      progress.value = 0.8;
      isProcessing.value = false;
      showRetryOption.value = true;

    } catch (e) {
      debugPrint('❌ [ResultController] Test verification polling failed: $e');
      verificationResult.value = VerificationResult.failed;
      processingStatus.value = 'Test verification failed: ${e.toString()}';
      progress.value = 0.0;
      isProcessing.value = false;
    }
  }

  void _extractVerifiedUserInfo(Map<String, dynamic> jobData) {
    try {
      debugPrint('🔍 [ResultController] Extracting user info from job data: ${jobData.keys}');

      // First try to get OCR extracted data (most reliable)
      if (jobData.containsKey('ocrExtractedData')) {
        final ocrData = jobData['ocrExtractedData'] as Map<String, dynamic>;
        debugPrint('📊 [ResultController] Found OCR data: $ocrData');

        verifiedName.value = ocrData['names'] ?? '';
        verifiedSurname.value = ocrData['surname'] ?? '';
        verifiedIdNumber.value = ocrData['personalIdNumber'] ?? '';
        verifiedSex.value = ocrData['sex'] ?? '';

        // Handle date of birth formatting
        final dobString = ocrData['dateOfBirth'] ?? '';
        if (dobString.isNotEmpty) {
          try {
            final dob = DateTime.parse(dobString);
            verifiedDateOfBirth.value = '${dob.day}/${dob.month}/${dob.year}';
          } catch (e) {
            verifiedDateOfBirth.value = dobString;
          }
        }

        debugPrint('✅ [ResultController] Extracted from OCR: ${verifiedSurname.value} ${verifiedName.value}, ID: ${verifiedIdNumber.value}');
        return;
      }

      // Fallback: try kycUserId if it's a populated object
      if (jobData.containsKey('kycUserId') && jobData['kycUserId'] is Map<String, dynamic>) {
        final userData = jobData['kycUserId'] as Map<String, dynamic>;
        debugPrint('👤 [ResultController] Found user data: ${userData.keys}');

        verifiedName.value = userData['names'] ?? '';
        verifiedSurname.value = userData['surname'] ?? '';
        verifiedIdNumber.value = userData['personalIdNumber'] ?? '';
        verifiedSex.value = userData['sex'] ?? '';

        final dobString = userData['dateOfBirth'] ?? '';
        if (dobString.isNotEmpty) {
          try {
            final dob = DateTime.parse(dobString);
            verifiedDateOfBirth.value = '${dob.day}/${dob.month}/${dob.year}';
          } catch (e) {
            verifiedDateOfBirth.value = dobString;
          }
        }

        debugPrint('✅ [ResultController] Extracted from kycUserId: ${verifiedSurname.value} ${verifiedName.value}');
        return;
      }

      debugPrint('⚠️ [ResultController] No extractable user info found in job data');
    } catch (e) {
      debugPrint('❌ [ResultController] Error extracting user info: $e');
    }
  }

  void _extractVerifiedUserInfoFromResult(Map<String, dynamic> results) {
    try {
      // Extract from verification results (for normal flow)
      if (results.containsKey('userInfo')) {
        final userInfo = results['userInfo'] as Map<String, dynamic>?;
        if (userInfo != null) {
          verifiedName.value = userInfo['names'] ?? '';
          verifiedSurname.value = userInfo['surname'] ?? '';
          verifiedIdNumber.value = userInfo['personalIdNumber'] ?? '';
          verifiedDateOfBirth.value = userInfo['dateOfBirth'] ?? '';
          verifiedSex.value = userInfo['sex'] ?? '';
        }
      }
      debugPrint('✅ [ResultController] Extracted user info from verification result');
    } catch (e) {
      debugPrint('❌ [ResultController] Error extracting user info from result: $e');
    }
  }
}