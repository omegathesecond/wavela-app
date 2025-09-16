import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/verification_api_service.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/file_upload_api_service.dart';
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
      debugPrint('🚀 [ResultController] Starting normal verification process...');

      final userModel = _verificationController.userModel;
      final documentType = _verificationController.selectedDocumentType.value;

      // Validate we have all required data
      if (userModel.idFrontImage == null || userModel.idBackImage == null || userModel.selfieImage == null) {
        throw Exception('Missing required images for verification');
      }

      processingStatus.value = 'Uploading your documents...';
      progress.value = 0.1;

      // Step 1: Upload files to get URLs
      final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
      final uploadResponses = await Get.find<FileUploadApiService>().uploadVerificationDocuments(
        jobId: jobId,
        idFrontPath: userModel.idFrontImage!,
        idBackPath: userModel.idBackImage!,
        selfiePath: userModel.selfieImage!,
        onProgress: (message, uploadProgress) {
          processingStatus.value = message;
          progress.value = 0.1 + (0.1 * uploadProgress); // 10% to 20%
        },
      );

      // Step 2: Now follow EXACTLY the same steps as test verification
      // Create verification with uploaded URLs
      final result = await _verificationApi.createVerification(
        idFrontUrl: uploadResponses['id_front']?.url,
        idBackUrl: uploadResponses['id_back']?.url,
        selfieUrl: uploadResponses['selfie']?.url,
        metadata: {
          'documentType': documentType,
        },
      );

      final actualJobId = result['jobId'] ?? result['id'];
      this.jobId.value = actualJobId;
      this.verificationId.value = result['id'];

      debugPrint('✅ [ResultController] Normal verification created - JobId: $actualJobId, VerificationId: ${result['id']}');

      // Step 3: Use EXACTLY the same polling as test verification
      processingStatus.value = 'Processing verification...';
      progress.value = 0.2;

      // Call the SAME polling method that test uses, just pass false to indicate normal
      await _startNormalVerificationPolling(actualJobId);

    } catch (e) {
      debugPrint('❌ [ResultController] Normal verification failed: $e');
      verificationResult.value = VerificationResult.failed;
      processingStatus.value = 'Verification failed: ${e.toString()}';
      progress.value = 0.0;
      isProcessing.value = false;
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

  // TEST VERIFICATION POLLING - DO NOT MODIFY (it works!)
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
          // Use direct API call
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
            // Manual review case - stop polling and show message
            verificationResult.value = VerificationResult.processing;
            processingStatus.value = 'Your verification requires manual review. You will be notified once complete.';
            progress.value = 0.8;
            isProcessing.value = false;
            debugPrint('⏸️ [ResultController] Verification requires manual review - stopping polling');
            return;
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

  // NORMAL VERIFICATION POLLING - COPY of test polling (just different messages)
  Future<void> _startNormalVerificationPolling(String jobId) async {
    try {
      debugPrint('🔄 [ResultController] Starting NORMAL verification polling for job: $jobId');

      // Poll job status
      const maxAttempts = 12;
      const pollInterval = Duration(seconds: 5);

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          debugPrint('📊 [ResultController] NORMAL polling attempt ${attempt + 1}/$maxAttempts for job: $jobId');

          // Use direct API call
          final response = await _apiService.get('/jobs/$jobId');
          debugPrint('📋 [ResultController] NORMAL verification raw response: ${response.data}');

          final jobData = response.data['data'] as Map<String, dynamic>;
          debugPrint('📋 [ResultController] NORMAL verification job data keys: ${jobData.keys}');

          // Update progress
          final progressValue = 0.5 + (0.5 * (attempt / maxAttempts));
          progress.value = progressValue;

          // Get current stage and status from API response
          final currentStage = jobData['currentStage'] as String? ?? 'submitted';
          final currentStatus = jobData['currentStatus'] as String? ?? jobData['status'] as String? ?? 'pending';

          debugPrint('🔍 [ResultController] NORMAL verification - Job status: $currentStatus, stage: $currentStage');

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

          // Check if job is complete
          if (currentStatus == 'completed') {
            verificationResult.value = VerificationResult.success;
            processingStatus.value = 'Verification completed successfully!';
            progress.value = 1.0;
            isProcessing.value = false;
            confidenceScore.value = 95;
            completionTime.value = _formatDateTime(DateTime.now());

            // Extract user information from job data for display
            _extractVerifiedUserInfo(jobData);
            return;
          } else if (currentStatus == 'rejected' || currentStatus == 'expired') {
            verificationResult.value = VerificationResult.failed;
            processingStatus.value = 'Verification failed';
            progress.value = 1.0;
            isProcessing.value = false;
            return;
          } else if (currentStatus == 'on_hold') {
            // Manual review case - stop polling and show message
            verificationResult.value = VerificationResult.processing;
            processingStatus.value = 'Your verification requires manual review. You will be notified once complete.';
            progress.value = 0.8;
            isProcessing.value = false;
            debugPrint('⏸️ [ResultController] Verification requires manual review - stopping polling');
            return;
          }

          // Wait before next poll
          await Future.delayed(pollInterval);
        } catch (e) {
          debugPrint('❌ [ResultController] NORMAL verification polling attempt ${attempt + 1} failed: $e');

          // Check if it's a 404 error (job not found)
          if (e.toString().contains('404')) {
            debugPrint('⚠️ [ResultController] NORMAL verification - Job not found. JobId might be incorrect: $jobId');
            verificationResult.value = VerificationResult.failed;
            processingStatus.value = 'Verification job not found. Please try again.';
            progress.value = 0.0;
            isProcessing.value = false;
            return;
          }

          if (attempt == maxAttempts - 1) {
            throw Exception('Failed to get job status after $maxAttempts attempts: $e');
          }

          // Wait before retrying on error
          await Future.delayed(pollInterval);
        }
      }

      // Timeout case
      verificationResult.value = VerificationResult.processing;
      processingStatus.value = 'Verification is taking longer than expected';
      progress.value = 0.8;
      isProcessing.value = false;
      showRetryOption.value = true;

    } catch (e) {
      debugPrint('❌ [ResultController] NORMAL verification polling failed: $e');
      verificationResult.value = VerificationResult.failed;
      processingStatus.value = 'Verification failed: ${e.toString()}';
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

}