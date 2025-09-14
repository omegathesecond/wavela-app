import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'fingerprint_controller.dart';
import '../../../../data/services/fingerprint_service.dart';

class FingerprintCapturePage extends GetView<FingerprintController> {
  const FingerprintCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Capture'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildConnectionStatus(),
              const SizedBox(height: 24),
              _buildFingerSelector(),
              const SizedBox(height: 24),
              _buildCaptureArea(),
              const SizedBox(height: 24),
              _buildCapturedFingerprints(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: controller.isConnected.value ? Colors.green[50] : Colors.grey[50],
        border: Border.all(
          color: controller.isConnected.value ? Colors.green[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Obx(() => Icon(
                controller.isConnected.value 
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: controller.isConnected.value 
                    ? Colors.green 
                    : Colors.red,
                size: 28,
              )),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                      controller.isConnected.value
                          ? 'Connected to Device'
                          : 'No Device Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: controller.isConnected.value ? Colors.green[800] : Colors.red[800],
                      ),
                    )),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      controller.isConnected.value 
                          ? controller.connectedDeviceName
                          : 'Tap "Discover Devices" to find fingerprint scanners',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.deviceStatus.value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          )),
          if (!controller.isConnected.value) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.discoverDevices,
                    icon: Obx(() => controller.isDiscovering.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search)),
                    label: Text(controller.isDiscovering.value ? 'Discovering...' : 'Discover Devices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (controller.hasAvailableDevices) ...[
              const SizedBox(height: 12),
              const Text('Available Devices:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...controller.availableDevices.map((device) => ListTile(
                dense: true,
                leading: Icon(Icons.fingerprint, color: Colors.blue),
                title: Text(device.name),
                subtitle: Text('${device.manufacturer} ${device.model}'),
                trailing: ElevatedButton(
                  onPressed: () => controller.connectToDevice(device),
                  child: const Text('Connect'),
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFingerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Choose Fingers to Capture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended: Start with thumbs (easier to position), then index fingers',
                  style: TextStyle(color: Colors.blue[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Recommended fingers section
        _buildRecommendedFingers(),
        const SizedBox(height: 20),
        
        // All fingers with hand diagrams
        _buildHandDiagrams(),
      ],
    );
  }

  Widget _buildRecommendedFingers() {
    final recommendedFingers = _fingerprintService.getRecommendedFingers();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              'Quick Capture (Thumbs First)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Text(
            '👍 Start with thumbs - they\'re easier to position and scan',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recommendedFingers.map((finger) {
            final isSelected = controller.selectedFinger.value == finger;
            final isCaptured = controller.capturedFingerprints.containsKey(finger);
            final quality = controller.capturedFingerprints[finger];
            
            return GestureDetector(
              onTap: () => controller.selectFinger(finger),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCaptured 
                      ? Colors.green[50]
                      : isSelected 
                          ? Colors.blue[100]
                          : Colors.grey[50],
                  border: Border.all(
                    color: isCaptured 
                        ? Colors.green
                        : isSelected 
                            ? Colors.blue
                            : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCaptured ? Icons.check_circle : Icons.fingerprint,
                      color: isCaptured 
                          ? Colors.green
                          : isSelected 
                              ? Colors.blue
                              : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fingerprintService.getFingerDisplayName(finger),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCaptured 
                                ? Colors.green[800]
                                : isSelected 
                                    ? Colors.blue[800]
                                    : Colors.grey[700],
                          ),
                        ),
                        if (isCaptured && quality != null)
                          Text(
                            'Quality: ${(quality * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildHandDiagrams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Available Fingers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildHandDiagram(true)), // Right hand
            const SizedBox(width: 16),
            Expanded(child: _buildHandDiagram(false)), // Left hand
          ],
        ),
      ],
    );
  }

  Widget _buildHandDiagram(bool isRightHand) {
    final handFingers = isRightHand 
        ? ['Right Little', 'Right Ring', 'Right Middle', 'Right Index', 'Right Thumb']
        : ['Left Thumb', 'Left Index', 'Left Middle', 'Left Ring', 'Left Little'];
    
    return Column(
      children: [
        Text(
          isRightHand ? 'Right Hand' : 'Left Hand',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: handFingers.map((finger) {
              return Obx(() {
                final isSelected = controller.selectedFinger.value == finger;
                final isCaptured = controller.capturedFingerprints.containsKey(finger);
                
                return GestureDetector(
                  onTap: () => controller.selectFinger(finger),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCaptured 
                          ? Colors.green[100]
                          : isSelected 
                              ? Colors.blue[100]
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCaptured 
                              ? Icons.check_circle 
                              : finger.contains('Thumb')
                                  ? Icons.thumb_up
                                  : Icons.radio_button_unchecked,
                          size: 16,
                          color: isCaptured 
                              ? Colors.green
                              : finger.contains('Thumb')
                                  ? Colors.orange
                                  : isSelected 
                                      ? Colors.blue
                                      : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                finger.split(' ').last, // Just the finger name
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isCaptured 
                                      ? Colors.green[800]
                                      : finger.contains('Thumb')
                                          ? Colors.orange[800]
                                          : isSelected 
                                              ? Colors.blue[800]
                                              : Colors.grey[700],
                                ),
                              ),
                              if (finger.contains('Thumb'))
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'BEST',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper to access the fingerprint service for method calls
  FingerprintService get _fingerprintService => Get.find<FingerprintService>();

  Widget _buildCaptureArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.isScanning.value 
                    ? Colors.blue 
                    : Colors.grey[300]!,
                width: controller.isScanning.value ? 2 : 1,
              ),
            ),
            child: Obx(() {
              if (controller.isScanning.value) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: controller.scanQuality.value,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              controller.scanQuality.value >= 0.7
                                  ? Colors.green
                                  : controller.scanQuality.value >= 0.4
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.fingerprint, 
                          size: 40, 
                          color: controller.scanQuality.value >= 0.7 
                              ? Colors.green 
                              : Colors.blue
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Device Reading...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep finger on device',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }
              
              final isConnected = controller.isConnected.value;
              final hasSelectedFinger = controller.selectedFinger.value.isNotEmpty;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint, 
                    size: 60, 
                    color: isConnected && hasSelectedFinger 
                        ? Colors.blue 
                        : Colors.grey
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConnected 
                        ? hasSelectedFinger 
                            ? 'Ready to capture'
                            : 'Select a finger first'
                        : 'Connect device first',
                    style: TextStyle(
                      color: isConnected && hasSelectedFinger 
                          ? Colors.blue 
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Obx(() => LinearProgressIndicator(
            value: controller.scanQuality.value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              controller.scanQuality.value >= 0.7
                  ? Colors.green
                  : controller.scanQuality.value >= 0.4
                  ? Colors.orange
                  : Colors.red,
            ),
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Quality: ${(controller.scanQuality.value * 100).toInt()}%',
            style: TextStyle(
              color: controller.scanQuality.value >= 0.7
                  ? Colors.green
                  : controller.scanQuality.value >= 0.4
                  ? Colors.orange
                  : Colors.red,
            ),
          )),
          const SizedBox(height: 16),
          Obx(() {
            final service = controller.fingerprintService;
            
            // Show retry button if capture failed
            if (service.captureFailedNeedsRetry.value) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.retryCapture,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.clearRetryState,
                    child: const Text('Choose Different Finger'),
                  ),
                ],
              );
            }
            
            // Normal capture button
            return ElevatedButton(
              onPressed: controller.canCapture 
                  ? controller.captureFingerprint 
                  : null,
              child: const Text('Capture Fingerprint'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCapturedFingerprints() {
    return Obx(() {
      if (controller.capturedFingerprints.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Captured Fingerprints',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...controller.capturedFingerprints.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    '${(entry.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => LinearProgressIndicator(
            value: controller.capturedFingerprints.length / 2,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Captured: ${controller.capturedFingerprints.length}/2 (minimum)',
            style: const TextStyle(fontSize: 12),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.hasMinimumFingerprints 
                      ? controller.completeCapture 
                      : null,
                  child: const Text('Complete'),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}