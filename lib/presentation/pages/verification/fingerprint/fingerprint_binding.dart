import 'package:get/get.dart';
import 'fingerprint_controller.dart';
import '../verification_controller.dart';

class FingerprintBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FingerprintController());
    // Ensure VerificationController is available
    if (!Get.isRegistered<VerificationController>()) {
      Get.lazyPut(() => VerificationController());
    }
  }
}