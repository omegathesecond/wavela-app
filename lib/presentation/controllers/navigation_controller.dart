import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  
  void changeIndex(int index) {
    currentIndex.value = index;
  }
  
  void navigateToHome() {
    Get.offAllNamed('/home');
  }
  
  void navigateToVerification() {
    Get.toNamed('/verification');
  }
  
  void navigateToIDCapture() {
    Get.toNamed('/verification/id-capture');
  }
  
  void navigateToSelfieCapture() {
    Get.toNamed('/verification/selfie');
  }
  
  void navigateToFingerprintCapture() {
    Get.toNamed('/verification/fingerprint');
  }
  
  void navigateToResult() {
    Get.toNamed('/verification/result');
  }
  
  void goBack() {
    Get.back();
  }
}