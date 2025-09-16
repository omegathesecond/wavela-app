import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/verification_api_service.dart';

class HomeController extends GetxController {
  
  HomeController() {
    debugPrint('[HomeController] Constructor called');
  }
  final RxList<Map<String, dynamic>> recentActivities = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    debugPrint('[HomeController] onInit called');
    super.onInit();
    loadRecentActivities();
  }

  void loadRecentActivities() {
    // This would normally load from storage or API
    // For now, we'll leave it empty
  }

  void startVerification() {
    Get.toNamed('/verification');
  }

  void scanID() {
    Get.toNamed('/verification/id-capture');
  }

  void takeSelfie() {
    Get.toNamed('/verification/selfie');
  }

  // void captureFingerprint() {
  //   Get.toNamed('/verification/fingerprint');
  // }

  void viewStatus() {
    Get.toNamed('/jobs');
  }

  void showInstructions() {
    debugPrint('[HomeController] Showing instructions/onboarding');
    Get.toNamed('/onboarding');
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

  void addActivity(String title, String status, IconData icon, Color color) {
    recentActivities.insert(0, {
      'title': title,
      'status': status,
      'icon': icon,
      'color': color,
      'time': 'Just now',
    });

    if (recentActivities.length > 5) {
      recentActivities.removeLast();
    }
  }

  Future<void> startTestVerification() async {
    try {
      debugPrint('[HomeController] Starting test verification with predefined data');

      // Ensure service is instantiated
      final verificationService = Get.put(VerificationApiService(), permanent: true);

      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Submit verification with test data
      final result = await verificationService.createVerification(
        idFrontUrl: "https://cdn.omevision.com/verifications/job_1757877941852_user_1757877941845/documents/1757877941478-id_front_CAP8742414580027235672.jpg",
        idBackUrl: "https://cdn.omevision.com/verifications/job_1757877941852_user_1757877941845/documents/1757877942932-id_back_CAP562885231393743215.jpg",
        selfieUrl: "https://cdn.omevision.com/verifications/job_1757877941852_user_1757877941845/documents/1757877943902-selfie_CAP8397752789325910072.jpg",
        metadata: {
          'documentType': 'national_id',
        },
      );

      // Close loading dialog
      Get.back();

      // Navigate to verification result page where polling happens
      Get.offAllNamed('/verification/result', arguments: {
        'jobId': result['jobId'] ?? result['id'],
        'verificationId': result['id'],
        'isTestVerification': true,
      });

      // Add activity to recent activities
      addActivity(
        'Test Verification Submitted',
        'Processing',
        Icons.science,
        Colors.orange,
      );

    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      debugPrint('[HomeController] Test verification failed: $e');
      Get.snackbar(
        'Verification Error',
        'Failed to start test verification: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}