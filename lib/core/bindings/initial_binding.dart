import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/services/camera_service.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/fingerprint_service.dart';
import '../../data/services/jobs_service.dart';
import '../../data/services/jobs_api_service.dart';
import '../../data/services/verification_api_service.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/file_upload_api_service.dart';
import '../../data/services/config_service.dart';
import '../../data/services/advanced_liveness_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('[InitialBinding] dependencies() called');
    // Storage and API services are already initialized in main.dart
    // Just ensure other services are available as lazy singletons
    Get.lazyPut(() => CameraService());
    Get.lazyPut(() => BiometricService());
    Get.lazyPut(() => OCRService());
    Get.lazyPut(() => FingerprintService());
    Get.lazyPut(() => JobsService());
    Get.lazyPut(() => JobsApiService());
    Get.lazyPut(() => VerificationApiService());
    Get.lazyPut(() => AuthApiService());
    Get.lazyPut(() => FileUploadApiService());
    Get.lazyPut(() => ConfigService());
    Get.lazyPut(() => AdvancedLivenessService());
    debugPrint('[InitialBinding] All services registered');
  }
}