/// Centralized API endpoints configuration
/// All API endpoints are defined here for easy management
class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String jobs = '/jobs';
  static const String media = '/media';
  static const String verification = '/verification';
  
  // Authentication endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  
  // User management endpoints
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile';
  static const String deleteAccount = '$users/account';
  
  // Media upload endpoints
  static const String upload = '$media/upload';
  static const String uploadMultiple = '$media/upload/multiple';
  static String mediaFile(String fileId) => '$media/files/$fileId';
  
  // Job management endpoints
  static const String createJob = jobs;
  static const String listJobs = jobs;
  static String jobDetails(String jobId) => '$jobs/$jobId';
  static String jobStatus(String jobId) => '$jobs/$jobId/status';
  static String cancelJob(String jobId) => '$jobs/$jobId/cancel';
  static String jobResults(String jobId) => '$jobs/$jobId/results';
  
  // Verification endpoints
  static const String startVerification = '$verification/start';
  static const String submitDocuments = '$verification/documents';
  static const String submitSelfie = '$verification/selfie';
  static const String submitFingerprints = '$verification/fingerprints';
  static String verificationStatus(String verificationId) => '$verification/$verificationId/status';
  static String verificationResults(String verificationId) => '$verification/$verificationId/results';
  static String retryVerification(String verificationId) => '$verification/$verificationId/retry';
  
  // Specialized verification endpoints
  static const String idCardExtraction = '$verification/id-extraction';
  static const String faceVerification = '$verification/face-verification';
  static const String livenessCheck = '$verification/liveness-check';
  static const String fingerprintAnalysis = '$verification/fingerprint-analysis';
  static const String backgroundCheck = '$verification/background-check';
  
  // System endpoints
  static const String health = '/health';
  static const String version = '/version';
  static const String config = '/config';
  
  // WebSocket endpoints (if needed)
  static const String wsJobs = '/ws/jobs';
  static const String wsVerification = '/ws/verification';
  
  // Utility methods
  static String withQuery(String endpoint, Map<String, dynamic> params) {
    if (params.isEmpty) return endpoint;
    
    final query = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return query.isEmpty ? endpoint : '$endpoint?$query';
  }
  
  // Common query parameters
  static Map<String, dynamic> paginationParams({
    int? page,
    int? limit,
    String? sort,
    String? order,
  }) {
    return {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (sort != null) 'sort': sort,
      if (order != null) 'order': order,
    };
  }
  
  static Map<String, dynamic> filterParams({
    String? status,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (fromDate != null) 'from_date': fromDate.toIso8601String(),
      if (toDate != null) 'to_date': toDate.toIso8601String(),
    };
  }
}