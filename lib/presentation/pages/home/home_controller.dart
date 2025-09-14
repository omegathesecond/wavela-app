import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  void captureFingerprint() {
    Get.toNamed('/verification/fingerprint');
  }

  void viewStatus() {
    Get.toNamed('/jobs');
  }

  void showInstructions() {
    debugPrint('[HomeController] Showing instructions/onboarding');
    Get.toNamed('/onboarding');
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
}