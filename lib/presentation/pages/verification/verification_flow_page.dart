import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'verification_controller.dart';

class VerificationFlowPage extends GetView<VerificationController> {
  const VerificationFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.onBackPressed,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Obx(() => _buildCurrentStep()),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Obx(() => Column(
        children: [
          Row(
            children: List.generate(
              controller.totalSteps,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= controller.currentStep.value
                        ? Get.theme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            controller.stepTitles[controller.currentStep.value],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildCurrentStep() {
    switch (controller.currentStep.value) {
      case 0:
        return _buildInstructionsStep();
      case 1:
        return _buildDocumentTypeStep();
      case 2:
        return _buildIDCaptureStep();
      case 3:
        return _buildSelfieStep();
      case 4:
        return _buildReviewStep();
      default:
        return Container();
    }
  }

  Widget _buildInstructionsStep() {
    return Column(
      children: [
        const Icon(
          Icons.info_outline,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 24),
        const Text(
          'Before You Begin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildInstructionItem(
          Icons.credit_card,
          'Have your National ID ready',
          'Ensure both sides are clearly visible',
        ),
        _buildInstructionItem(
          Icons.light_mode,
          'Good lighting',
          'Find a well-lit area for clear photos',
        ),
        _buildInstructionItem(
          Icons.fingerprint,
          'Fingerprint reader connected',
          'Ensure the device is properly connected',
        ),
        _buildInstructionItem(
          Icons.timer,
          '2-3 minutes needed',
          'The process is quick and secure',
        ),
      ],
    );
  }

  Widget _buildInstructionItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Get.theme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeStep() {
    return Column(
      children: [
        const Text(
          'Select Document Type',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Obx(() => Column(
          children: [
            _buildDocumentOption(
              'National ID',
              'Eswatini National Identity Card',
              Icons.credit_card,
              'national_id',
            ),
            _buildDocumentOption(
              'Passport',
              'International Passport (Coming Soon)',
              Icons.book,
              'passport',
              enabled: false,
            ),
            _buildDocumentOption(
              'Driver\'s License',
              'Driving License (Coming Soon)',
              Icons.drive_eta,
              'drivers_license',
              enabled: false,
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDocumentOption(
    String title,
    String subtitle,
    IconData icon,
    String value, {
    bool enabled = true,
  }) {
    final isSelected = controller.selectedDocumentType.value == value;
    
    return GestureDetector(
      onTap: enabled ? () => controller.selectDocumentType(value) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected ? Get.theme.primaryColor.withValues(alpha: 0.1) : Colors.white)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? (isSelected ? Get.theme.primaryColor : Colors.grey[300]!)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (isSelected ? Get.theme.primaryColor : Colors.grey[600])
                  : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: enabled ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Get.theme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCaptureStep() {
    return Column(
      children: [
        const Icon(
          Icons.credit_card,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 24),
        const Text(
          'Capture Your ID',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please capture both sides of your National ID',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed('/verification/id-capture'),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Open Camera'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfieStep() {
    return Column(
      children: [
        const Icon(
          Icons.face,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Take a Selfie',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'We\'ll match your face with the photo on your ID',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed('/verification/selfie'),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Selfie'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Review & Submit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please review your information before submitting',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        _buildVerificationSummary(),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: controller.submitVerification,
          icon: const Icon(Icons.send),
          label: const Text('Submit Verification'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Document Type
          _buildSummaryItem(
            'Document Type',
            controller.selectedDocumentType.value,
            Icons.description,
          ),
          
          // ID Documents
          _buildSummaryItem(
            'ID Documents',
            (controller.userModel.idFrontImage != null && 
             controller.userModel.idBackImage != null) 
                ? 'Front & Back captured' 
                : 'Not captured',
            Icons.credit_card,
            isComplete: controller.userModel.idFrontImage != null && 
                       controller.userModel.idBackImage != null,
          ),
          
          // Selfie
          _buildSummaryItem(
            'Selfie Photo',
            controller.userModel.selfieImage != null 
                ? 'Captured' 
                : 'Not captured',
            Icons.face,
            isComplete: controller.userModel.selfieImage != null,
          ),
          
          // Fingerprints
          _buildFingerprintSummary(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String status, IconData icon, {bool isComplete = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isComplete ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: isComplete ? Colors.green[700] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isComplete ? Icons.check_circle : Icons.pending,
            color: isComplete ? Colors.green : Colors.orange,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildFingerprintSummary() {
    final fingerprints = controller.userModel.fingerprints ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            color: fingerprints.isNotEmpty ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fingerprints',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  fingerprints.isNotEmpty 
                      ? '${fingerprints.length} fingerprint(s) captured'
                      : 'Not captured',
                  style: TextStyle(
                    color: fingerprints.isNotEmpty 
                        ? Colors.green[700] 
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (fingerprints.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: fingerprints.map((fp) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text(
                        '${fp.finger} (${(fp.quality * 100).toInt()}%)',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            fingerprints.isNotEmpty ? Icons.check_circle : Icons.pending,
            color: fingerprints.isNotEmpty ? Colors.green : Colors.orange,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
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
      child: Row(
        children: [
          Obx(() => controller.currentStep.value > 0
              ? Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    child: const Text('Previous'),
                  ),
                )
              : const SizedBox()),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => ElevatedButton(
              onPressed: (controller.canProceed.value && !controller.isNavigating.value) 
                ? (controller.currentStep.value == controller.totalSteps - 1 
                   ? controller.submitVerification 
                   : controller.nextStep)
                : null,
              child: controller.isNavigating.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    controller.currentStep.value == controller.totalSteps - 1
                        ? 'Submit'
                        : 'Next',
                  ),
            )),
          ),
        ],
      ),
    );
  }
}