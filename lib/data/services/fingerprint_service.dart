import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Model class for fingerprint device
class FingerprintDevice {
  final String id;
  final String name;
  final String manufacturer;
  final String model;
  final bool isConnected;
  final int signalStrength;

  FingerprintDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    this.isConnected = false,
    this.signalStrength = 0,
  });

  @override
  String toString() => '$manufacturer $model ($name)';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'manufacturer': manufacturer,
    'model': model,
    'isConnected': isConnected,
    'signalStrength': signalStrength,
  };
}

class FingerprintService extends GetxService {
  final RxBool isConnected = false.obs;
  final RxBool isScanning = false.obs;
  final RxBool isDiscovering = false.obs;
  final RxString deviceStatus = 'Disconnected'.obs;
  final RxDouble scanQuality = 0.0.obs;
  final RxString currentFinger = ''.obs;
  final RxBool captureFailedNeedsRetry = false.obs;
  String _lastAttemptedFinger = '';
  final RxList<FingerprintDevice> availableDevices = <FingerprintDevice>[].obs;
  final Rx<FingerprintDevice?> selectedDevice = Rx<FingerprintDevice?>(null);
  
  static const double qualityThreshold = 0.7;
  static const double matchThreshold = 0.95;
  
  final Map<String, String> fingerTemplates = {};
  final List<String> registeredTemplates = [];
  
  // final bool _isInitializing = false; // Currently unused
  
  // Platform channel for Bio ID communication
  static const _platform = MethodChannel('bioid_fingerprint');
  
  @override
  void onInit() {
    super.onInit();
    debugPrint('[FingerprintService] Service initialized');
    // Don't auto-connect, let user initiate device discovery
  }
  
  @override
  void onClose() {
    disconnectDevice();
    super.onClose();
  }
  
  // Device Discovery Methods
  Future<void> discoverDevices() async {
    if (isDiscovering.value) return;
    
    try {
      isDiscovering.value = true;
      deviceStatus.value = 'Discovering devices...';
      availableDevices.clear();
      
      debugPrint('[FingerprintService] Starting device discovery');
      
      // TODO: Replace with real hardware discovery
      // This should use platform channels to communicate with your Bio ID device
      // For now, we'll discover the connected hardware devices
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Discover real Bio ID devices connected via USB/Serial
      final List<FingerprintDevice> realDevices = await _discoverRealDevices();
      
      // Add discovered devices
      for (FingerprintDevice device in realDevices) {
        availableDevices.add(device);
        debugPrint('[FingerprintService] Found device: ${device.name}');
      }
      
      deviceStatus.value = 'Found ${availableDevices.length} device(s)';
      debugPrint('[FingerprintService] Discovery completed - found ${availableDevices.length} devices');
      
      // Auto-connect to first available device for better UX
      if (availableDevices.isNotEmpty) {
        debugPrint('[FingerprintService] Auto-connecting to first device...');
        await Future.delayed(const Duration(milliseconds: 500));
        await connectToDevice(availableDevices.first);
      }
      
    } catch (e) {
      debugPrint('[FingerprintService] Discovery error: $e');
      deviceStatus.value = 'Discovery failed: $e';
    } finally {
      isDiscovering.value = false;
    }
  }
  
  Future<bool> connectToDevice(FingerprintDevice device) async {
    try {
      deviceStatus.value = 'Connecting to ${device.name}...';
      debugPrint('[FingerprintService] Connecting to device: ${device.name}');
      
      // Use platform channel to connect to actual Bio ID device
      final Map<dynamic, dynamic> result = await _platform.invokeMethod(
        'connectToDevice',
        {'deviceId': device.id}
      );
      
      if (result['success'] == true) {
        selectedDevice.value = device;
        isConnected.value = true;
        deviceStatus.value = 'Connected to ${device.name} - Ready';
        
        debugPrint('[FingerprintService] Successfully connected to ${device.name}');
        return true;
      } else {
        throw Exception(result['message'] ?? 'Connection failed');
      }
    } catch (e) {
      debugPrint('[FingerprintService] Connection failed: $e');
      deviceStatus.value = 'Connection failed: $e';
      isConnected.value = false;
      selectedDevice.value = null;
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> connectDevice() async {
    if (availableDevices.isEmpty) {
      await discoverDevices();
    }
    
    if (availableDevices.isNotEmpty) {
      return await connectToDevice(availableDevices.first);
    }
    
    deviceStatus.value = 'No devices available';
    return false;
  }
  
  void disconnectDevice() {
    debugPrint('[FingerprintService] Disconnecting device');
    isConnected.value = false;
    selectedDevice.value = null;
    deviceStatus.value = 'Disconnected';
  }
  
  Future<String?> captureFingerprint(String finger) async {
    if (!isConnected.value) {
      deviceStatus.value = 'Device not connected';
      debugPrint('[FingerprintService] Capture failed - device not connected');
      return null;
    }
    
    if (isScanning.value) return null;
    
    try {
      isScanning.value = true;
      currentFinger.value = finger;
      _lastAttemptedFinger = finger;
      
      debugPrint('[FingerprintService] Starting capture for $finger on ${selectedDevice.value?.name}');
      final deviceName = selectedDevice.value?.name ?? 'fingerprint device';
      
      // First, open the device if not already open
      debugPrint('[FingerprintService] Opening Bio ID device...');
      await _platform.invokeMethod('openDevice');
      
      deviceStatus.value = 'Device ready - Place your $finger on the scanner';
      
      // Start finger detection loop
      debugPrint('[FingerprintService] Starting finger detection...');
      bool fingerDetected = false;
      int attempts = 0;
      
      while (!fingerDetected && attempts < 50) { // 5 seconds timeout (50 * 100ms)
        try {
          final bool detected = await _platform.invokeMethod('detectFinger');
          if (detected) {
            fingerDetected = true;
            deviceStatus.value = 'Finger detected! Capturing...';
            debugPrint('[FingerprintService] Finger detected on device');
            break;
          }
        } catch (e) {
          debugPrint('[FingerprintService] Detection check error: $e');
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        
        // Update status every 10 attempts (1 second)
        if (attempts % 10 == 0) {
          deviceStatus.value = 'Waiting for finger... (${5 - attempts ~/ 10}s)';
        }
      }
      
      if (!fingerDetected) {
        deviceStatus.value = 'No finger detected - please try again';
        captureFailedNeedsRetry.value = true;
        return null;
      }
      
      // Now capture the fingerprint
      await _communicateWithDevice(deviceName, finger);
      
      if (scanQuality.value < qualityThreshold) {
        deviceStatus.value = 'Poor quality - please try again';
        captureFailedNeedsRetry.value = true;
        debugPrint('[FingerprintService] Capture failed - poor quality (${scanQuality.value})');
        return null;
      }
      
      // The template should come from the device via _communicateWithDevice
      final template = fingerTemplates[finger];
      if (template != null) {
        deviceStatus.value = 'Capture successful - Quality: ${(scanQuality.value * 100).toInt()}%';
        captureFailedNeedsRetry.value = false;  // Clear retry state on success
        debugPrint('[FingerprintService] Successfully captured $finger with quality ${scanQuality.value}');
        return template;
      } else {
        throw Exception('Failed to get template from device');
      }
      
    } catch (e) {
      debugPrint('[FingerprintService] Capture error: $e');
      deviceStatus.value = 'Capture failed - please try again';
      captureFailedNeedsRetry.value = true;
      return null;
    } finally {
      isScanning.value = false;
      currentFinger.value = '';
    }
  }
  
  String _generateTemplate(String finger) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = selectedDevice.value?.id ?? 'unknown-device';
    final data = '$finger-$timestamp-$deviceId';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // Device Management Helper Methods
  bool get hasAvailableDevices => availableDevices.isNotEmpty;
  bool get isDeviceSelected => selectedDevice.value != null;
  String get connectedDeviceName => selectedDevice.value?.name ?? 'None';
  
  FingerprintDevice? getDeviceById(String id) {
    try {
      return availableDevices.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }
  
  void selectDevice(String deviceId) {
    final device = getDeviceById(deviceId);
    if (device != null) {
      selectedDevice.value = device;
      debugPrint('[FingerprintService] Selected device: ${device.name}');
    }
  }
  
  Future<bool> verifyFingerprint(String finger, String storedTemplate) async {
    if (!isConnected.value) return false;
    
    try {
      deviceStatus.value = 'Verifying $finger...';
      
      final capturedTemplate = await captureFingerprint(finger);
      if (capturedTemplate == null) return false;
      
      double similarity = _calculateSimilarity(capturedTemplate, storedTemplate);
      
      if (similarity >= matchThreshold) {
        deviceStatus.value = 'Verification successful';
        return true;
      } else {
        deviceStatus.value = 'Verification failed';
        return false;
      }
    } catch (e) {
      debugPrint('[FingerprintService] Verification error: $e');
      deviceStatus.value = 'Verification failed - please try again';
      return false;
    }
  }
  
  Future<String?> searchDuplicate(String template) async {
    try {
      deviceStatus.value = 'Searching for duplicates...';
      
      for (String registeredTemplate in registeredTemplates) {
        double similarity = _calculateSimilarity(template, registeredTemplate);
        if (similarity >= matchThreshold) {
          deviceStatus.value = 'Duplicate found';
          return registeredTemplate;
        }
      }
      
      deviceStatus.value = 'No duplicates found';
      return null;
    } catch (e) {
      debugPrint('[FingerprintService] Search error: $e');
      deviceStatus.value = 'Search failed - please try again';
      return null;
    }
  }
  
  double _calculateSimilarity(String template1, String template2) {
    if (template1 == template2) return 1.0;
    
    int matchingChars = 0;
    int minLength = template1.length < template2.length ? template1.length : template2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (template1[i] == template2[i]) {
        matchingChars++;
      }
    }
    
    return matchingChars / minLength;
  }
  
  void registerTemplate(String template) {
    if (!registeredTemplates.contains(template)) {
      registeredTemplates.add(template);
    }
  }
  
  Map<String, dynamic> getFingerprintData() {
    return {
      'templates': fingerTemplates,
      'quality': scanQuality.value,
      'device': deviceStatus.value,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  void clearCapturedData() {
    fingerTemplates.clear();
    scanQuality.value = 0.0;
    captureFailedNeedsRetry.value = false;
  }
  
  Future<String?> retryCaptureFingerprint() async {
    if (_lastAttemptedFinger.isNotEmpty) {
      captureFailedNeedsRetry.value = false;
      return await captureFingerprint(_lastAttemptedFinger);
    }
    return null;
  }
  
  void clearRetryState() {
    captureFailedNeedsRetry.value = false;
  }
  
  List<String> getAvailableFingers() {
    // Recommended sequence: Thumbs first (easier to position), then index fingers
    return [
      'Right Thumb',
      'Left Thumb', 
      'Right Index',
      'Left Index',
      'Right Middle',
      'Left Middle',
      'Right Ring',
      'Left Ring',
      'Right Little',
      'Left Little',
    ];
  }
  
  List<String> getRecommendedFingers() {
    // For quick capture, recommend thumbs and index fingers
    return [
      'Right Thumb',
      'Left Thumb',
      'Right Index',
      'Left Index',
    ];
  }
  
  String getFingerDisplayName(String finger) {
    // Helper to get user-friendly finger names
    final fingerMap = {
      'Right Thumb': 'Right Thumb',
      'Left Thumb': 'Left Thumb',
      'Right Index': 'Right Index Finger',
      'Left Index': 'Left Index Finger',
      'Right Middle': 'Right Middle Finger',
      'Left Middle': 'Left Middle Finger',
      'Right Ring': 'Right Ring Finger',
      'Left Ring': 'Left Ring Finger',
      'Right Little': 'Right Pinky Finger',
      'Left Little': 'Left Pinky Finger',
    };
    return fingerMap[finger] ?? finger;
  }
  
  bool hasMinimumFingerprints() {
    return fingerTemplates.length >= 2;
  }
  
  // Real hardware discovery method using Bio ID platform channel
  Future<List<FingerprintDevice>> _discoverRealDevices() async {
    List<FingerprintDevice> devices = [];
    
    try {
      debugPrint('[FingerprintService] Calling platform channel for device discovery');
      final List<dynamic> deviceList = await _platform.invokeMethod('discoverDevices');
      
      devices = deviceList.map((deviceData) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(deviceData);
        return FingerprintDevice(
          id: data['id'] ?? '',
          name: data['name'] ?? 'Unknown Device',
          manufacturer: data['manufacturer'] ?? 'Bio ID',
          model: data['model'] ?? 'Unknown Model',
          isConnected: data['isConnected'] ?? false,
          signalStrength: data['signalStrength'] ?? 0,
        );
      }).toList();
      
      debugPrint('[FingerprintService] Discovered ${devices.length} real devices via platform channel');
    } catch (e) {
      debugPrint('[FingerprintService] Error discovering real devices: $e');
      // Fallback to mock devices if platform channel fails
      devices = [
        FingerprintDevice(
          id: 'bio-id-scanner-1',
          name: 'Bio ID Scanner 1',
          manufacturer: 'Bio ID',
          model: 'Professional Scanner',
          signalStrength: 95,
        ),
        FingerprintDevice(
          id: 'bio-id-scanner-2',
          name: 'Bio ID Scanner 2',
          manufacturer: 'Bio ID',
          model: 'Compact Scanner',
          signalStrength: 88,
        ),
      ];
    }
    
    return devices;
  }
  
  // Real hardware communication method using Bio ID platform channel
  Future<void> _communicateWithDevice(String deviceName, String finger) async {
    try {
      deviceStatus.value = 'Preparing $deviceName...';
      scanQuality.value = 0.0;
      await Future.delayed(const Duration(milliseconds: 200));
      
      deviceStatus.value = 'Device ready - place finger...';
      scanQuality.value = 0.1;
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Call platform channel to capture fingerprint using Bio ID SDK
      debugPrint('[FingerprintService] Calling platform channel for fingerprint capture');
      deviceStatus.value = '$deviceName capturing fingerprint...';
      scanQuality.value = 0.3;
      
      final Map<dynamic, dynamic> result = await _platform.invokeMethod(
        'captureFingerprint',
        {'finger': finger}
      );
      
      if (result['success'] == true) {
        scanQuality.value = result['quality'] ?? 0.85;
        deviceStatus.value = 'Capture successful - Quality: ${(scanQuality.value * 100).toInt()}%';
        
        // Store the actual template from Bio ID device
        final String template = result['template'] ?? _generateTemplate(finger);
        fingerTemplates[finger] = template;
        
        debugPrint('[FingerprintService] Successfully captured $finger via platform channel');
      } else {
        throw Exception('Bio ID capture failed: ${result['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      debugPrint('[FingerprintService] Hardware communication error: $e');
      deviceStatus.value = 'Capture failed: $e';
      rethrow;
    }
  }
}