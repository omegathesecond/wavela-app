import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'dart:math' as math;
import '../models/job_model.dart';
import 'jobs_api_service.dart';
import 'file_upload_api_service.dart';
import 'api_service.dart';

/// Verification API service that handles server-side verification
/// Uses R2 upload + verification creation pattern for better security and scalability
class VerificationApiService extends getx.GetxService {
  late JobsApiService _jobsApi;
  late FileUploadApiService _fileUploadApi;
  late ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    _jobsApi = getx.Get.find<JobsApiService>();
    _fileUploadApi = getx.Get.find<FileUploadApiService>();
    _apiService = getx.Get.find<ApiService>();
  }

  /// Starts a simple KYC verification - just upload files and poll job status
  Future<VerificationResult> startKYCVerification({
    String? idFrontPath,
    String? idBackPath,
    String? selfiePath,
    Map<String, dynamic>? metadata,
    Function(VerificationProgress)? onProgress,
  }) async {
    try {
      // Generate a job ID for uploads
      final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
      
      onProgress?.call(VerificationProgress(
        stage: 'uploading',
        message: 'Uploading documents...',
        progress: 0.1,
      ));

      // Upload documents to backend
      final uploadResponses = await _fileUploadApi.uploadVerificationDocuments(
        jobId: jobId,
        idFrontPath: idFrontPath,
        idBackPath: idBackPath,
        selfiePath: selfiePath,
        onProgress: (message, progress) {
          onProgress?.call(VerificationProgress(
            stage: 'uploading',
            message: message,
            progress: 0.1 + (0.3 * progress), // 10% to 40%
          ));
        },
      );

      onProgress?.call(VerificationProgress(
        stage: 'processing',
        message: 'Starting verification...',
        progress: 0.4,
      ));

      // Create verification job 
      final verificationData = await createVerification(
        idFrontUrl: uploadResponses['id_front']?.url,
        idBackUrl: uploadResponses['id_back']?.url,
        selfieUrl: uploadResponses['selfie']?.url,
        metadata: metadata,
      );

      final verificationId = verificationData['id'];
      final actualJobId = verificationData['jobId'] ?? jobId;

      // Poll job status until completion
      final finalStatus = await _pollJobStatus(
        actualJobId,
        onProgress: (progress) {
          onProgress?.call(progress);
        },
      );

      return VerificationResult(
        jobId: actualJobId,
        verificationId: verificationId,
        status: _mapJobStatusToVerificationStatus(finalStatus.status),
        isSuccessful: finalStatus.status == JobStatus.completed,
        message: finalStatus.status == JobStatus.completed 
            ? 'Verification completed successfully' 
            : 'Verification failed',
        results: {},
        errors: finalStatus.status == JobStatus.rejected 
            ? ['Verification was rejected'] 
            : [],
        completedAt: DateTime.now(),
        rejectionReason: finalStatus.status == JobStatus.rejected 
            ? 'Document verification failed' 
            : null,
      );

    } catch (e) {
      debugPrint('❌ [VerificationApiService] Error: $e');
      
      onProgress?.call(VerificationProgress(
        stage: 'error',
        message: 'Verification failed: ${e.toString()}',
        progress: 0.0,
        error: e.toString(),
      ));

      return VerificationResult(
        jobId: '',
        verificationId: '',
        status: JobStatus.rejected,
        isSuccessful: false,
        message: 'Verification failed',
        results: {},
        errors: [e.toString()],
        completedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Creates a verification with R2 URLs
  Future<Map<String, dynamic>> createVerification({
    String? idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('🔧 [VerificationApiService] Creating verification...');
    
    final data = <String, dynamic>{
      'documentType': 'National ID', // Default to National ID to match enum
    };

    if (idFrontUrl != null) data['idFrontImage'] = idFrontUrl;
    if (idBackUrl != null) data['idBackImage'] = idBackUrl;
    if (selfieUrl != null) data['selfieImage'] = selfieUrl;

    // Override document type if provided in metadata
    if (metadata != null && metadata.containsKey('documentType')) {
      data['documentType'] = metadata['documentType'];
    }

    debugPrint('📊 [VerificationApiService] Verification data: $data');

    try {
      final response = await _apiService.post('/verifications', data: data);
      debugPrint('✅ [VerificationApiService] Verification created successfully');
      debugPrint('📄 [VerificationApiService] Response: ${response.data}');
      return response.data['data'];
    } catch (e) {
      debugPrint('❌ [VerificationApiService] Failed to create verification: $e');
      rethrow;
    }
  }

  /// Polls job status until completion
  Future<JobModel> _pollJobStatus(
    String jobId, {
    Function(VerificationProgress)? onProgress,
  }) async {
    const maxAttempts = 60; // 5 minutes with 5-second intervals
    const pollInterval = Duration(seconds: 5);
    
    debugPrint('🔄 [VerificationApiService] Starting to poll job status: $jobId');
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      debugPrint('🔄 [VerificationApiService] Poll attempt $attempt for job: $jobId');
      
      try {
        // Use direct API call with proper authentication
        final response = await _apiService.get('/jobs/$jobId');
        final status = JobModel.fromJson(response.data['data'] ?? response.data);
        
        // Simple progress calculation
        final progress = 0.4 + (0.6 * (attempt / maxAttempts));
        final message = _getProgressMessage(status);
        
        onProgress?.call(VerificationProgress(
          stage: 'processing',
          message: message,
          progress: progress,
          currentStage: status.currentStage.name,
          jobStatus: status.status.name,
        ));
        
        debugPrint('📊 [VerificationApiService] Job status: ${status.status.name}');
        
        // Check if processing is complete
        if (status.status == JobStatus.completed || 
            status.status == JobStatus.rejected ||
            status.status == JobStatus.expired) {
          debugPrint('✅ [VerificationApiService] Job completed with status: ${status.status.name}');
          return status;
        }
        
      } catch (e) {
        debugPrint('❌ [VerificationApiService] Failed to get job status: $e');
        if (attempt == maxAttempts - 1) {
          throw Exception('Failed to get job status: $e');
        }
      }
      
      // Wait before next poll
      await Future.delayed(pollInterval);
    }
    
    throw Exception('Verification timeout - please check status later');
  }


  String _getProgressMessage(JobModel status) {
    switch (status.currentStage) {
      case JobStage.submitted:
        return 'Documents received...';
      case JobStage.ocrProcessing:
        return 'Extracting text from documents (OCR)...';
      case JobStage.documentReview:
        return 'Reviewing document authenticity...';
      case JobStage.faceVerification:
        return 'Verifying identity match...';
      case JobStage.fingerprintAnalysis:
        return 'Analyzing biometrics...';
      case JobStage.backgroundCheck:
        return 'Conducting background check...';
      case JobStage.finalReview:
        return 'Final review in progress...';
      case JobStage.completed:
        return 'Verification completed!';
    }
  }

  JobStatus _mapJobStatusToVerificationStatus(JobStatus status) {
    // Direct mapping for now, can be customized later
    return status;
  }

  /// Gets the current status of a verification job
  Future<JobModel> getVerificationStatus(String jobId) async {
    final response = await _apiService.get('/jobs/$jobId');
    return JobModel.fromJson(response.data['data'] ?? response.data);
  }
}

/// Progress information for verification process
class VerificationProgress {
  final String stage;
  final String message;
  final double progress; // 0.0 to 1.0
  final String? currentStage;
  final String? jobStatus;
  final String? error;

  VerificationProgress({
    required this.stage,
    required this.message,
    required this.progress,
    this.currentStage,
    this.jobStatus,
    this.error,
  });
}

/// Final verification result
class VerificationResult {
  final String jobId;
  final String verificationId;
  final JobStatus status;
  final bool isSuccessful;
  final String message;
  final Map<String, dynamic> results;
  final List<String> errors;
  final DateTime completedAt;
  final String? rejectionReason;
  final String? error;

  VerificationResult({
    required this.jobId,
    required this.verificationId,
    required this.status,
    required this.isSuccessful,
    required this.message,
    required this.results,
    required this.errors,
    required this.completedAt,
    this.rejectionReason,
    this.error,
  });


  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'verificationId': verificationId,
      'status': status.name,
      'isSuccessful': isSuccessful,
      'message': message,
      'results': results,
      'errors': errors,
      'completedAt': completedAt.toIso8601String(),
      'rejectionReason': rejectionReason,
      'error': error,
    };
  }
}