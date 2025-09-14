import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import '../config/endpoints.dart';
import '../models/job_model.dart';
import 'api_service.dart';

/// Jobs API service that extends the base ApiService
/// Handles all job-related API calls with proper error handling and polling
class JobsApiService extends getx.GetxService {
  late ApiService _apiService;
  
  @override
  void onInit() {
    super.onInit();
    _apiService = getx.Get.find<ApiService>();
  }
  
  /// Creates a new verification job
  /// Returns the job ID for tracking
  Future<JobModel> createVerificationJob({
    required String userId,
    required String verificationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createJob,
        data: {
          'user_id': userId,
          'type': 'verification',
          'subtype': verificationType,
          'status': 'pending',
          'metadata': metadata ?? {},
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      return JobModel.fromJson(response.data);
    } catch (e) {
      throw _handleJobError('Failed to create verification job', e);
    }
  }
  
  /// Uploads files for a job (ID cards, selfie, etc.)
  /// Returns updated job with file references
  Future<JobModel> uploadJobFiles({
    required String jobId,
    required List<String> filePaths,
    required String fileType, // 'id_front', 'id_back', 'selfie', 'fingerprint'
    Map<String, String>? additionalData,
  }) async {
    try {
      final formData = FormData();
      
      // Add files to form data
      for (int i = 0; i < filePaths.length; i++) {
        final fileName = '${fileType}_${i + 1}.jpg';
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(filePaths[i], filename: fileName),
          ),
        );
      }
      
      // Add job metadata
      formData.fields.addAll([
        MapEntry('job_id', jobId),
        MapEntry('file_type', fileType),
        MapEntry('uploaded_at', DateTime.now().toIso8601String()),
      ]);
      
      // Add any additional data
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });
      }
      
      await _apiService.post(
        ApiEndpoints.upload,
        data: formData,
      );
      
      // Return updated job status
      final updatedJob = await getJobStatus(jobId);
      return updatedJob;
    } catch (e) {
      throw _handleJobError('Failed to upload files for job', e);
    }
  }
  
  /// Gets the current status of a job
  Future<JobModel> getJobStatus(String jobId) async {
    try {
      debugPrint('📋 [JobsApiService] Getting job status for: $jobId');
      final response = await _apiService.get(
        ApiEndpoints.jobStatus(jobId),
      );
      debugPrint('✅ [JobsApiService] Job status response: ${response.data}');
      
      return JobModel.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [JobsApiService] Failed to get job status for $jobId: $e');
      throw _handleJobError('Failed to get job status', e);
    }
  }
  
  /// Gets all jobs for the current user
  Future<List<JobModel>> getUserJobs({
    int? page,
    int? limit,
    String? status,
    String? type,
  }) async {
    try {
      final queryParams = {
        ...ApiEndpoints.paginationParams(page: page, limit: limit),
        ...ApiEndpoints.filterParams(status: status, type: type),
      };
      
      final endpoint = ApiEndpoints.withQuery(ApiEndpoints.listJobs, queryParams);
      final response = await _apiService.get(endpoint);
      
      final List<dynamic> jobsJson = response.data['jobs'] ?? response.data;
      return jobsJson.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleJobError('Failed to get user jobs', e);
    }
  }
  
  /// Gets detailed job results
  Future<Map<String, dynamic>> getJobResults(String jobId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.jobResults(jobId),
      );
      
      return response.data;
    } catch (e) {
      throw _handleJobError('Failed to get job results', e);
    }
  }
  
  /// Polls job status until completion or timeout
  /// Returns the final job status
  Future<JobModel> pollJobUntilComplete({
    required String jobId,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    Function(JobModel)? onStatusUpdate,
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final job = await getJobStatus(jobId);
        
        // Notify caller of status update
        onStatusUpdate?.call(job);
        
        // Check if job is complete
        if (_isJobComplete(job.status.name)) {
          return job;
        }
        
        // Check if job failed
        if (_isJobFailed(job.status.name)) {
          throw JobException('Job failed with status: ${job.status.name}', job);
        }
        
        // Wait before next poll
        await Future.delayed(pollInterval);
      } catch (e) {
        if (e is JobException) rethrow;
        throw _handleJobError('Error polling job status', e);
      }
    }
    
    throw JobException('Job polling timeout after ${timeout.inMinutes} minutes', null);
  }
  
  /// Cancels a job
  Future<JobModel> cancelJob(String jobId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.cancelJob(jobId),
        data: {
          'cancelled_at': DateTime.now().toIso8601String(),
        },
      );
      
      return JobModel.fromJson(response.data);
    } catch (e) {
      throw _handleJobError('Failed to cancel job', e);
    }
  }
  
  /// Retries a failed job
  Future<JobModel> retryJob(String jobId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.retryVerification(jobId),
        data: {
          'retried_at': DateTime.now().toIso8601String(),
        },
      );
      
      return JobModel.fromJson(response.data);
    } catch (e) {
      throw _handleJobError('Failed to retry job', e);
    }
  }
  
  /// Starts a complete verification flow
  /// This is a convenience method that creates job, uploads files, and polls
  Future<JobModel> startCompleteVerification({
    required String userId,
    String? idFrontPath,
    String? idBackPath,
    String? selfiePath,
    List<String>? fingerprintPaths,
    Map<String, dynamic>? metadata,
    Function(JobModel)? onStatusUpdate,
  }) async {
    try {
      // 1. Create verification job
      JobModel job = await createVerificationJob(
        userId: userId,
        verificationType: 'complete_kyc',
        metadata: metadata,
      );
      
      // 2. Upload ID documents if provided
      if (idFrontPath != null || idBackPath != null) {
        final idPaths = <String>[];
        if (idFrontPath != null) idPaths.add(idFrontPath);
        if (idBackPath != null) idPaths.add(idBackPath);
        
        job = await uploadJobFiles(
          jobId: job.id,
          filePaths: idPaths,
          fileType: 'identity_document',
          additionalData: {
            'has_front': idFrontPath != null ? 'true' : 'false',
            'has_back': idBackPath != null ? 'true' : 'false',
          },
        );
      }
      
      // 3. Upload selfie if provided
      if (selfiePath != null) {
        job = await uploadJobFiles(
          jobId: job.id,
          filePaths: [selfiePath],
          fileType: 'selfie',
        );
      }
      
      // 4. Upload fingerprints if provided
      if (fingerprintPaths != null && fingerprintPaths.isNotEmpty) {
        job = await uploadJobFiles(
          jobId: job.id,
          filePaths: fingerprintPaths,
          fileType: 'fingerprints',
        );
      }
      
      // 5. Poll until completion
      return await pollJobUntilComplete(
        jobId: job.id,
        onStatusUpdate: onStatusUpdate,
      );
    } catch (e) {
      throw _handleJobError('Failed to complete verification flow', e);
    }
  }
  
  // Helper methods
  bool _isJobComplete(String status) {
    return ['completed', 'success', 'verified'].contains(status.toLowerCase());
  }
  
  bool _isJobFailed(String status) {
    return ['failed', 'error', 'rejected', 'cancelled'].contains(status.toLowerCase());
  }
  
  Exception _handleJobError(String message, dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final errorMessage = error.response?.data?['message'] ?? error.message;
      return JobException('$message: $errorMessage (Status: $statusCode)', null);
    }
    return JobException('$message: ${error.toString()}', null);
  }
}

/// Custom exception for job-related errors
class JobException implements Exception {
  final String message;
  final JobModel? job;
  
  const JobException(this.message, this.job);
  
  @override
  String toString() => 'JobException: $message';
}