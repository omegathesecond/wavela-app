import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void next() {
    debugPrint('[OnboardingController] next() called, currentPage: ${currentPage.value}');
    if (currentPage.value == 3) {
      debugPrint('[OnboardingController] Final page, navigating to /home');
      try {
        Get.offNamed('/home');
        debugPrint('[OnboardingController] Navigation to /home completed');
      } catch (e) {
        debugPrint('[OnboardingController] Error navigating to /home: $e');
      }
    } else {
      debugPrint('[OnboardingController] Moving to next page');
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    debugPrint('[OnboardingController] skip() called');
    try {
      Get.offNamed('/home');
      debugPrint('[OnboardingController] Skip navigation to /home completed');
    } catch (e) {
      debugPrint('[OnboardingController] Error skipping to /home: $e');
    }
  }
}