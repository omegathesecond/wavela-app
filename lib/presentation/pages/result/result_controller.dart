import 'package:get/get.dart';
import 'package:flutter/services.dart';

class ResultController extends GetxController {
  final RxBool isVerificationSuccessful = false.obs;
  final RxMap<String, dynamic> extractedData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> faceMatchResult = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> livenessResult = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      extractedData.value = arguments['extractedData'] ?? {};
      
      final verificationResults = arguments['verificationResults'] ?? {};
      faceMatchResult.value = verificationResults['faceMatch'] ?? {};
      livenessResult.value = verificationResults['liveness'] ?? {};
      
      // Determine overall success
      _calculateOverallResult();
    }
  }

  void _calculateOverallResult() {
    final faceMatch = faceMatchResult['match'] ?? false;
    final isLive = livenessResult['isLive'] ?? false;
    final hasExtractedData = extractedData.isNotEmpty;
    
    isVerificationSuccessful.value = faceMatch && isLive && hasExtractedData;
  }

  void startNewVerification() {
    Get.offAllNamed('/camera');
  }

  void shareResults() {
    final resultText = '''
Wavela - Identity Verification Results

Status: ${isVerificationSuccessful.value ? 'VERIFIED' : 'FAILED'}

Face Match: ${faceMatchResult['match'] == true ? 'PASS' : 'FAIL'} (${faceMatchResult['confidence'] ?? 0}%)
Liveness: ${livenessResult['isLive'] == true ? 'PASS' : 'FAIL'} (${livenessResult['confidence'] ?? 0}%)

Timestamp: ${DateTime.now().toString()}
''';
    
    Clipboard.setData(ClipboardData(text: resultText));
    
    Get.snackbar(
      'Results Copied',
      'Verification results copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}