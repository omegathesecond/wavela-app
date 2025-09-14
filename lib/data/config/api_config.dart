import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/config_service.dart';

class ApiConfig {
  static ConfigService get _config => Get.find<ConfigService>();
  
  // Base URL
  static String get baseUrl => _config.baseUrl;
  
  // API Key
  static String get apiKey => _config.apiKey;
  
  // API key validation
  static bool isApiKeyValid(String key) {
    return _config.isApiKeyValid;
  }
  
  // API endpoints
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  
  static const String verifications = '/verifications';
  static String verification(String id) => '/verifications/$id';
  
  static const String jobs = '/jobs';
  static String job(String id) => '/jobs/$id';
  static String jobStage(String id) => '/jobs/$id/stage';
  static String jobStatus(String id) => '/jobs/$id/status';
  
  static const String filesUpload = '/files/upload';
  static const String filesUploadMultiple = '/files/upload-multiple';
  static const String filesUploadBase64 = '/files/upload-base64';
  
  static String user(String id) => '/users/$id';
  
  static const String statsDashboard = '/stats/dashboard';
  static const String statsProcessingTimes = '/stats/processing-times';
  
  // Timeout configurations
  static Duration get connectTimeout => Duration(seconds: _config.connectTimeout);
  static Duration get receiveTimeout => Duration(seconds: _config.receiveTimeout);
  static Duration get sendTimeout => Duration(seconds: _config.sendTimeout);
  
  // File upload configurations
  static int get maxFileSize => _config.maxFileSize;
  static List<String> get allowedImageFormats => _config.allowedFormats;
  static double get minImageQuality => _config.imageQuality;
  
  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

// Environment configuration
class ApiEnvironment {
  static ConfigService get _config => Get.find<ConfigService>();
  
  static String get current => _config.environment;
  
  static bool get isDevelopment => _config.isDevelopment;
  static bool get isStaging => _config.isStaging;
  static bool get isProduction => _config.isProduction;
  
  // Enable/disable features based on environment
  static bool get enableMockData => _config.enableMockData;
  static bool get enableLogging => _config.enableApiLogging;
  static bool get enableDebugMode => _config.enableDebugMode;
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    debugPrint('🔧 API Configuration:');
    debugPrint('   Base URL: ${ApiConfig.baseUrl}');
    debugPrint('   Environment: $current');
    debugPrint('   API Key Valid: ${ApiConfig.isApiKeyValid(ApiConfig.apiKey)}');
    debugPrint('   Debug Mode: $enableDebugMode');
    debugPrint('   Logging: $enableLogging');
  }
}