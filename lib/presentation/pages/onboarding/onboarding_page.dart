import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: [
                  _buildPage(
                    'Secure Identity Verification',
                    'Verify your identity quickly and securely with our advanced KYC system',
                    Icons.security,
                  ),
                  _buildPage(
                    'Document Scanning',
                    'Scan your national ID card with OCR technology for instant data extraction',
                    Icons.document_scanner,
                  ),
                  _buildPage(
                    'Biometric Verification',
                    'Enhanced security with face matching and fingerprint verification',
                    Icons.fingerprint,
                  ),
                  _buildPage(
                    'Fast & Reliable',
                    'Complete verification in under 2 minutes with bank-grade security',
                    Icons.speed,
                  ),
                ],
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Get.theme.primaryColor,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: controller.currentPage.value == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: controller.currentPage.value == index
                      ? Get.theme.primaryColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          )),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: controller.skip,
                child: const Text('Skip'),
              ),
              Obx(() => ElevatedButton(
                onPressed: controller.next,
                child: Text(
                  controller.currentPage.value == 3 ? 'Get Started' : 'Next',
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}