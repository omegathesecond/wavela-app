import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/jobs_service.dart';

class VerificationController extends GetxController {
  final RxInt currentStep = 0.obs;
  final RxBool canProceed = true.obs;
  final RxString selectedDocumentType = 'national_id'.obs;
  
  final int totalSteps = 5;  // Reduced from 6 - removed fingerprint step
  
  final List<String> stepTitles = [
    'Instructions',
    'Document Type',
    'ID Capture',
    'Selfie & Liveness',
    'Review & Submit',
  ];
  
  UserModel userModel = UserModel();
  
  final RxBool isNavigating = false.obs;

  void nextStep() {
    debugPrint('[VerificationController] nextStep() called, current step: ${currentStep.value}');
    
    if (currentStep.value < totalSteps - 1) {
      debugPrint('[VerificationController] Not at last step, validating current step...');
      if (validateCurrentStep()) {
        debugPrint('[VerificationController] Step validation passed, advancing from ${currentStep.value} to ${currentStep.value + 1}');
        
        // Show navigation loading briefly
        isNavigating.value = true;
        
        Future.delayed(const Duration(milliseconds: 300), () {
          currentStep.value++;
          updateCanProceed();
          isNavigating.value = false;
          debugPrint('[VerificationController] Advanced to step: ${currentStep.value}');
          
          // If we just advanced to the review step, do NOT submit automatically
          if (currentStep.value == 4) {  // Updated from 5 to 4 after removing fingerprint step
            debugPrint('[VerificationController] Now on Review step (4) - user must click Submit button to proceed');
          }
        });
      } else {
        debugPrint('[VerificationController] Step validation failed for step ${currentStep.value}');
      }
    } else {
      debugPrint('[VerificationController] At last step (${currentStep.value}), but nextStep should not submit directly!');
      debugPrint('[VerificationController] Submission should only happen via Submit button on review page');
    }
  }
  
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      updateCanProceed();
    }
  }
  
  bool validateCurrentStep() {
    debugPrint('[VerificationController] validateCurrentStep() for step: ${currentStep.value}');
    
    switch (currentStep.value) {
      case 0: // Instructions
        debugPrint('[VerificationController] Step 0 (Instructions): always valid');
        return true;
      case 1: // Document Type
        final isValid = selectedDocumentType.value.isNotEmpty;
        debugPrint('[VerificationController] Step 1 (Document Type): $isValid (type: ${selectedDocumentType.value})');
        return isValid;
      case 2: // ID Capture
        final isValid = userModel.idFrontImage != null && userModel.idBackImage != null;
        debugPrint('[VerificationController] Step 2 (ID Capture): $isValid (front: ${userModel.idFrontImage != null}, back: ${userModel.idBackImage != null})');
        return isValid;
      case 3: // Selfie
        final isValid = userModel.selfieImage != null;
        debugPrint('[VerificationController] Step 3 (Selfie): $isValid (selfie: ${userModel.selfieImage != null})');
        return isValid;
      case 4: // Fingerprint
        final isValid = userModel.fingerprints?.isNotEmpty ?? false;
        debugPrint('[VerificationController] Step 4 (Fingerprint): $isValid (fingerprints count: ${userModel.fingerprints?.length ?? 0})');
        return isValid;
      case 5: // Review
        debugPrint('[VerificationController] Step 5 (Review): always valid');
        return true;
      default:
        debugPrint('[VerificationController] Unknown step: ${currentStep.value}');
        return false;
    }
  }
  
  void updateCanProceed() {
    canProceed.value = validateCurrentStep();
  }
  
  void selectDocumentType(String type) {
    selectedDocumentType.value = type;
    updateCanProceed();
  }
  
  void onBackPressed() {
    if (currentStep.value > 0) {
      previousStep();
    } else {
      Get.back();
    }
  }
  
  Future<void> submitVerification() async {
    try {
      // Show loading dialog
      Get.dialog(
        PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Submitting verification...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we process your data',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Set verification as processing
      userModel = userModel.copyWith(
        verificationStatus: VerificationStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      
      // Get services
      final apiService = Get.find<ApiService>();
      final storageService = Get.find<StorageService>();
      final jobsService = Get.find<JobsService>();
      
      // Create job for tracking
      final job = await jobsService.createJobFromVerification(
        documentType: selectedDocumentType.value == 'national_id' ? 'National ID' : selectedDocumentType.value,
        userModel: userModel,
      );
      
      // Save verification data locally first
      await storageService.saveObject('current_verification', userModel.toJson());
      await storageService.addToVerificationQueue(userModel.toJson());
      
      // Prepare submission data
      final submissionData = {
        'documentType': selectedDocumentType.value,
        'userModel': userModel.toJson(),
        'submittedAt': DateTime.now().toIso8601String(),
      };
      
      // Submit to API (this can be done in background)
      try {
        final response = await apiService.post('/verifications', data: submissionData);
        
        // Update with server response if successful
        if (response.statusCode == 200 || response.statusCode == 201) {
          final verificationId = response.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          userModel = userModel.copyWith(
            id: verificationId,
            verificationStatus: VerificationStatus.inProgress,
          );
          await storageService.saveObject('current_verification', userModel.toJson());
        }
      } catch (apiError) {
        debugPrint('[VerificationController] API submission failed, saved locally: $apiError');
        // Continue anyway - data is saved locally
      }
      
      // Close loading dialog
      Get.back();
      
      // Show success message
      Get.snackbar(
        'Submission Successful!',
        'Your verification job ${job.id} is now being processed',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // Navigate to result/jobs page
      Get.offAllNamed('/verification/result');
      
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      debugPrint('[VerificationController] Submission error: $e');
      Get.snackbar(
        'Submission Error',
        'Failed to submit verification. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }
  
  void setIDImages(String frontPath, String backPath) {
    userModel = userModel.copyWith(
      idFrontImage: frontPath,
      idBackImage: backPath,
    );
    updateCanProceed();
  }
  
  void setSelfieImage(String path) {
    userModel = userModel.copyWith(selfieImage: path);
    updateCanProceed();
  }
  
  void setFingerprintData(List<FingerprintData> fingerprints) {
    userModel = userModel.copyWith(fingerprints: fingerprints);
    updateCanProceed();
  }
}