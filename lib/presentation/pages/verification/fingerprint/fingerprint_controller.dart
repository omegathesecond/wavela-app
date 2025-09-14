import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/fingerprint_service.dart';
import '../../../../data/models/user_model.dart';
import '../verification_controller.dart';

class FingerprintController extends GetxController {
  final FingerprintService _fingerprintService = Get.find<FingerprintService>();
  
  final RxString selectedFinger = ''.obs;
  final RxMap<String, double> capturedFingerprints = <String, double>{}.obs;
  final RxBool showDeviceSelector = false.obs;
  
  // Reactive getters from service
  RxBool get isConnected => _fingerprintService.isConnected;
  RxBool get isScanning => _fingerprintService.isScanning;
  RxBool get isDiscovering => _fingerprintService.isDiscovering;
  RxString get deviceStatus => _fingerprintService.deviceStatus;
  RxDouble get scanQuality => _fingerprintService.scanQuality;
  
  // Device management getters
  RxList<FingerprintDevice> get availableDevices => _fingerprintService.availableDevices;
  Rx<FingerprintDevice?> get selectedDevice => _fingerprintService.selectedDevice;
  bool get hasAvailableDevices => _fingerprintService.hasAvailableDevices;
  String get connectedDeviceName => _fingerprintService.connectedDeviceName;
  
  List<String> get availableFingers => _fingerprintService.getAvailableFingers();
  
  FingerprintService get fingerprintService => _fingerprintService;
  
  bool get canCapture => 
      isConnected.value && 
      selectedFinger.value.isNotEmpty && 
      !isScanning.value;
  
  bool get hasMinimumFingerprints => capturedFingerprints.length >= 2;

  @override
  void onInit() {
    super.onInit();
    // Start with device discovery and auto-connection
    discoverDevices();
    
    // Listen for connection changes to provide guidance
    ever(isConnected, (connected) {
      if (connected) {
        _showConnectionSuccessGuidance();
      }
    });
  }

  Future<void> discoverDevices() async {
    await _fingerprintService.discoverDevices();
  }

  Future<void> connectDevice() async {
    await _fingerprintService.connectDevice();
  }
  
  Future<void> connectToDevice(FingerprintDevice device) async {
    await _fingerprintService.connectToDevice(device);
  }

  void selectFinger(String finger) {
    if (!capturedFingerprints.containsKey(finger)) {
      selectedFinger.value = finger;
      
      // Auto-start capture when finger is selected and device is connected
      if (isConnected.value) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (selectedFinger.value == finger && canCapture) {
            debugPrint('[FingerprintController] Auto-starting capture for $finger');
            captureFingerprint();
          }
        });
      }
    }
  }

  Future<void> captureFingerprint() async {
    if (!canCapture) return;
    
    final template = await _fingerprintService.captureFingerprint(
      selectedFinger.value
    );
    
    if (template != null) {
      capturedFingerprints[selectedFinger.value] = scanQuality.value;
      
      Get.snackbar(
        'Success',
        '${selectedFinger.value} captured successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      
      selectedFinger.value = '';
    }
  }
  
  Future<void> retryCapture() async {
    final template = await _fingerprintService.retryCaptureFingerprint();
    
    if (template != null) {
      capturedFingerprints[selectedFinger.value] = scanQuality.value;
      
      Get.snackbar(
        'Success',
        '${selectedFinger.value} captured successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      
      selectedFinger.value = '';
    }
  }
  
  void clearRetryState() {
    _fingerprintService.clearRetryState();
    selectedFinger.value = '';
  }

  void completeCapture() async {
    debugPrint('[FingerprintController] completeCapture() called');
    
    if (!hasMinimumFingerprints) {
      debugPrint('[FingerprintController] Not enough fingerprints: ${capturedFingerprints.length}');
      Get.snackbar(
        'Incomplete',
        'Please capture at least 2 fingerprints',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }
    
    debugPrint('[FingerprintController] Has minimum fingerprints: ${capturedFingerprints.length}');
    
    try {
      // Get the verification controller
      debugPrint('[FingerprintController] Looking for VerificationController...');
      final verificationController = Get.find<VerificationController>();
      debugPrint('[FingerprintController] Found VerificationController, current step: ${verificationController.currentStep.value}');
      
      // In full verification flow, we should be on step 4 (fingerprint) when completing
      debugPrint('[FingerprintController] Expected step: 4 (Fingerprint), actual step: ${verificationController.currentStep.value}');
      
      // Ensure we're on the correct step before advancing
      if (verificationController.currentStep.value < 4) {
        debugPrint('[FingerprintController] Setting step to 4 (Fingerprint) before advancing');
        verificationController.currentStep.value = 4;
      }
      
      // Create fingerprint data list
      final fingerprintDataList = capturedFingerprints.entries.map((e) => 
        FingerprintData(
          finger: e.key,
          quality: e.value,
          template: _fingerprintService.fingerTemplates[e.key] ?? 'template_${e.key}',
          capturedAt: DateTime.now(),
        )
      ).toList();
      
      debugPrint('[FingerprintController] Created fingerprint data list with ${fingerprintDataList.length} items');
      
      // Update the user model with captured fingerprints using the proper method
      verificationController.setFingerprintData(fingerprintDataList);
      debugPrint('[FingerprintController] Updated verification controller with fingerprint data');
      
      // Show success message
      Get.snackbar(
        'Success!',
        'Captured ${fingerprintDataList.length} fingerprint(s) successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      
      // First, update the step in verification controller
      debugPrint('[FingerprintController] Current step before update: ${verificationController.currentStep.value}');
      
      // Ensure we're on step 4 before advancing
      if (verificationController.currentStep.value != 4) {
        verificationController.currentStep.value = 4;
      }
      
      // Now advance to step 5 (Review)
      debugPrint('[FingerprintController] Advancing to Review step');
      verificationController.nextStep();
      
      // Give the controller time to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Go back to the verification flow page
      debugPrint('[FingerprintController] Going back to verification flow, should show step ${verificationController.currentStep.value}');
      Get.back();
      
      debugPrint('[FingerprintController] Navigation completed');
      
    } catch (e) {
      debugPrint('[FingerprintController] Error completing capture: $e');
      Get.back(result: {
        'fingerprints': capturedFingerprints.entries.map((e) => {
          'finger': e.key,
          'quality': e.value,
          'template': 'template_${e.key}',
        }).toList(),
      });
    }
  }

  void _showConnectionSuccessGuidance() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (selectedFinger.value.isEmpty && capturedFingerprints.isEmpty) {
        Get.snackbar(
          '🎉 Device Connected!',
          'Ready to capture fingerprints. Select a finger below to start with thumbs.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        
        // Auto-select the first recommended finger (Right Thumb)
        Future.delayed(const Duration(seconds: 2), () {
          final recommended = _fingerprintService.getRecommendedFingers();
          if (recommended.isNotEmpty && selectedFinger.value.isEmpty) {
            selectFinger(recommended.first);
          }
        });
      }
    });
  }
}